class Verification::Residence
  include ActiveModel::Model
  include ActiveModel::Dates
  include ActiveModel::Validations::Callbacks

  attr_accessor :user, :document_number, :document_type, :date_of_birth, :postal_code, :terms_of_service, :redeemable_code

  before_validation :call_census_api

  validates :document_number, presence: true
  validates :document_type, presence: true
  validates :date_of_birth, presence: true
  validates :postal_code, presence: true
  validates :terms_of_service, acceptance: { allow_nil: false }
  validates :postal_code, length: { is: 5 }

  validate :allowed_age
  validate :document_number_uniqueness
  validate :redeemable_code_is_redeemable
  validate :document_letter

  def initialize(attrs = {})
    self.date_of_birth = parse_date('date_of_birth', attrs)
    attrs = remove_date('date_of_birth', attrs)
    super
    self.redeemable_code ||= self.user.try(:redeemable_code)
    clean_document_number
  end

  def save
    return false unless valid?

    user.take_votes_if_erased_document(document_number, document_type)

    user.update(document_number:       document_number,
                document_type:         document_type,
                date_of_birth:         date_of_birth.to_datetime,
                residence_verified_at: Time.current,
                verified_at:           Time.current)

    if redeemable_code.present?
      RedeemableCode.redeem(redeemable_code, user)
    end
    true
  end

  def allowed_age
    return if errors[:date_of_birth].any? ||  Age.in_years(date_of_birth) >= User.minimum_required_age
    errors.add(:date_of_birth, I18n.t('verification.residence.new.error_not_allowed_age'))
  end

  def document_number_uniqueness
    errors.add(:document_number, I18n.t('errors.messages.taken')) if User.active.where(document_number: document_number).any?
  end

  def redeemable_code_is_redeemable
    return if redeemable_code.blank?
    unless RedeemableCode.redeemable?(redeemable_code)
      errors.add(:redeemable_code, I18n.t('verification.residence.new.error_can_not_redeem_code'))
    end
  end

  def document_letter
    if document_type == '1'
      clean_document_number
      sent_letter = get_document_letter(document_type, document_number)
      calculated_letter = calculate_dni_letter(split_letter_from(document_number)[0].to_f)
      regular =  /[0-9]{8}[a-z]/i
      errors.add(:document_number, I18n.t('verification.residence.new.dni_validation_failed')) unless sent_letter == calculated_letter && regular.match(document_number)
    elsif document_type == '3'
      clean_document_number
      sent_letter = get_document_letter(document_type, document_number)
      #sustituimos la primera letra por un 0 para calcular la letra
      first_letter=document_number[0]
      replace_first_nie_letter_for_number(document_number)
      calculated_letter = calculate_dni_letter(split_letter_from(document_number)[0].to_f)
      document_number[0] = first_letter
      regular= /[X-Z][0-9]{7,8}[A-Z]/i
      errors.add(:document_number, I18n.t('verification.residence.new.nie_validation_failed'))  unless sent_letter == calculated_letter && regular.match(document_number)
    elsif document_type == '2'
      ' '
    else
      nil
    end

  end

  def store_failed_attempt
    FailedCensusCall.create(
      user: user,
      document_number: document_number,
      document_type: document_type,
      date_of_birth: date_of_birth,
      postal_code: postal_code,
      district_code: district_code
    )
  end

  def geozone
    Geozone.where(census_code: district_code).first if district_code.present?
  end

  private

    def call_census_api
      if  document_type.blank? || document_number.blank?
        @census_api_response = nil
      else
        document_number_four_last = get_document_number_last_four(document_type, document_number)
        doc_letter =  get_document_letter(document_type, document_number)
        @census_api_response = CensusApi.new.call(document_type, document_number_four_last, date_of_birth,doc_letter)
      end
    end

    def residency_valid?
      Setting["feature.skip_census_api"] ||
      @census_api_response.valid?
    end

    def clean_document_number
      self.document_number = document_number.gsub(/[^a-z0-9]+/i, "").upcase if document_number.present?
    end

    def is_dni?(document_type)
      document_type.to_s == "1"
    end

    def is_nie?(document_type)
      document_type.to_s == "3"
    end

    def get_document_letter(document_type, document_number)
      # Delete all non-alphanumerics.upcase
      document_number = document_number.to_s.gsub(/[^0-9A-Za-z]/i, '').upcase
      if document_type == '1' || document_type == '3'
        letter = document_number.last
      else
        letter = ' '
      end
    end

    def get_document_number_last_four(document_type, document_number)
      # Delete all non-alphanumerics
      document_number = document_number.to_s.gsub(/[^0-9A-Za-z]/i, '')
      if is_dni?(document_type) || is_nie?(document_type)
        document_number, letter = split_letter_from(document_number)
        return document_number.last(4).to_s
      else # if not a DNI, just use the document_number, with no variants
        document_number.last(4).to_s
      end
    end

    def split_letter_from(document_number)
      letter = document_number.last
      if letter[/[A-Za-z]/] == letter
        document_number = document_number[0..-2]
      else
        letter = nil
      end
      return document_number, letter
    end

    def replace_first_nie_letter_for_number(document_number)
      case document_number[0]
        when 'X'
          document_number[0] = '0'
        when 'Y'
          document_number[0] = '1'
        when 'Z'
          document_number[0] = '2'
        else
      end
    end

    def calculate_dni_letter(nif)
      seq = 'TRWAGMYFPDXBNJZSQVHLCKE'
      seq[nif % seq.length]
    end

end