module DocumentParser

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
end
