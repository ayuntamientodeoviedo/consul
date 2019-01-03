class Census < ActiveRecord::Base

  establish_connection :"oracle_production"

  #Ese usuario tiene permisos de SELECT sobre la vista REPOS.V_HAB_VOTA

  #Dicha vista contiene los siguientes campos:
  #FECNAC (DATE) – Es la fecha de nacimiento del habitante.
  #DOCUMENTO (VARCHAR2(4)) – Son los cuatro últimos dígitos del documento del habitante.
  #LETRA (VARCHAR2(1)) – Es la letra del documento del habitante.
  #TIPDOC (NUMBER(1)) – Tipo de documento ( 0-Sin especificar, 1-DNI, 2-Pasaporte, 3-Tarjeta de Residencia).


  # specify schema and table name
  self.table_name = Rails.env == "development" ? "census" : "REPOS.V_HAB_VOTA"

  # specify primary key name
  # ActiveRecord makes assumptions about primary keys.  It is expecting to find a primary key on your fact_prp table called "ID".  If your primary key is called something else, you will also need to set it as well
  self.primary_key = "DOCUMENTO" unless Rails.env == "development"
  self.primary_key = "documento" if Rails.env == "development"

  set_date_columns :FECNAC unless Rails.env == "development"
  set_string_columns :LETRA unless Rails.env == "development"
  set_integer_columns :TIPDOC  unless Rails.env == "development"
  
end    