include DocumentParser
class CensusApi

  def call(document_type , document_number, birth_date, letter)
    response = nil
    response = Response.new(get_response_body(document_type, document_number, birth_date, letter))
    response
  end

  def call_dni(document_type , document_number)
    document_number_four_last = get_document_number_last_four(document_type, document_number)
    doc_letter =  get_document_letter(document_type, document_number)
    response = nil
    response = Response.new(get_dni(document_type, document_number_four_last, doc_letter))
    response
  end

  class Response
    def initialize(census)
      @census = census
    end

    def valid?
      @census.present?
    end

    def date_of_birth
      @census.fecnac
    end

    private

      def data
        @census
      end
  end

  private

    def get_response_body(document_type, document_number, birth_date, letter)
      @census = Census.where('TIPDOC IN (?, \'0\') AND DOCUMENTO =? AND LETRA = ? and FECNAC = ?   ', document_type, document_number, letter , birth_date).first
    end

    def get_dni(document_type, document_number, letter)
      @census = Census.where('TIPDOC IN (?, \'0\') AND DOCUMENTO =? AND LETRA = ?', document_type, document_number, letter).first
    end

end