class CensusCaller

  def call(document_type, document_number)
    response = CensusApi.new.call(document_type, document_number)
    response = LocalCensus.new.call(document_type, document_number) unless response.valid?

    response
  end

  def call_dni(document_type , document_number)
    response = CensusApi.new.call_dni(document_type, document_number)
    response
  end

end
