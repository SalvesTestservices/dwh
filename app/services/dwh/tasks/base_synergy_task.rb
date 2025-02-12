class Dwh::Tasks::BaseSynergyTask
  def get_api_keys(name)
    case name
    when "globe"
      api_url        = ENV["DWH_CLICKKER_GLOBE_URL"]
      api_key        = ENV["DWH_CLICKKER_GLOBE_KEY"]
      administration = ENV["DWH_CLICKKER_GLOBE_ADMINISTRATION"]
    when "synergy"
      api_url        = ENV["DWH_CLICKKER_SYNERGY_URL"]
      api_key        = ENV["DWH_CLICKKER_SYNERGY_KEY"]
      administration = ENV["DWH_CLICKKER_SYNERGY_ADMINISTRATION"]
    end
    
    return api_url, api_key, administration
  end

  def send_get_request(api_url, api_key, administration, request)
    headers = set_headers(api_key, administration)

    max_retries = 3
    attempts = 0

    begin
      # Send the API POST request
      response = HTTParty.get("#{api_url}/#{request}", headers: headers, timeout: 300)
      JSON.parse(response.body) unless response.body.include?("Internal server error")
    rescue
      attempts += 1
      if attempts < max_retries
        retry
      else
        return "CONNECTION ERROR"
      end
    end
  end

  def send_custom_query(api_url, api_key, administration, verification_code, query)
    max_retries = 3
    attempts = 0

    begin
      headers = set_headers(api_key, administration)
    
      # Set the message body to get the data
      json = set_json(query, verification_code)

      # Send the API POST request
      response = HTTParty.post("#{api_url}/CustomQuery", headers: headers, body: json, timeout: 300)
      JSON.parse(response.body) unless response.body.include?("Internal server error")
    rescue
      attempts += 1
      if attempts < max_retries
        retry
      else
        return "CONNECTION ERROR"
      end
    end
  end
  
  def set_headers(api_key, administration)
    headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json",
      "X-ApiKey"  => api_key,
      "Administration" => administration
    }
  end
  
  def set_json(query, verification_code)
    {
      Query: "#{query}",
      VerificationCode: "#{verification_code}"
    }.to_json
  end
  
  def filled(month)
    month.to_s.rjust(3, " ")
  end

  def role_field(user_role)
    case user_role
    when "Manager Operations", "Accountmanager", "Director Sales & Business Development Solutions", "Unit lead", "Director QA & Testing advisory", "Competence lead", "Marketeer", "Engagement & Employability Lead", "Chapterlead", "HR Manager", "Directeur HR & Engagement", "Corporate Accountmanager", "Tribelead", "Academy Teamleider","Senior Manager Operations", "Manager Business Support Services", "Senior Manager Finance & Control", "Manager HRS", "HR Teamleider"
      role = "manager"
    when "Chief Financial Officer", "Finance Medewerker", "Chief Commercial Officer", "Planning and Support", "Chief Operations Officer", "Office Huismeester"
      role = "backoffice_admin"
    when "HR Medewerker", "Recruiter", "HR Administrator"
      role = "company_admin"
    else
      role = "employee"
    end
    
    I18n.t(".users.roles.#{role}")
  end

  def get_contract(user_id)
    contract = nil
    raw_contract = nil

    api_url, api_key, administration = get_api_keys("valori")
    administration = ENV["DW_CLICKKER_VALORI_SYNERGY_ADMINISTRATION"]

    query = "SELECT absences.ID AS ID, absences.HID AS HID, absences.EmpID as EmployeeID, absences.FreeTextField_01 AS Type, absences.FreeTextField_15 AS TypeDesc, absences.startdate AS StartDate, absences.enddate AS EndDate, absences.Description AS Description, (CASE WHEN CAST(absences.DocumentID AS char(40)) IS NULL THEN 0 ELSE 1 END) AS AttachmentPresent FROM absences WHERE absences.Type=11001 AND absences.EmpID=#{user_id} ORDER BY absences.FreeTextField_15,absences.startdate,absences.HID"
    body = send_custom_query(api_url, api_key, administration, "", query)

    # When there are no errors, then the verification code can be used to get the data
    if body["Errors"].blank?
      # Get the data
      body = send_custom_query(api_url, api_key, administration, "#{body["VerificationCode"]}", query)

      # Iterate over the results
      if body["Errors"].blank?
        body["Results"].each do |result|
          raw_contract = result["Type"]
        end
      end
    end

    unless raw_contract.blank?
      contract = raw_contract == "BWONBEPAALD" ? "#{I18n.t('.users.contracts.fixed')}" : "#{I18n.t('.users.contracts.temporary')}"
    end

    contract
  end

  def get_valid_hr_data(api_url, api_key, administration, original_id, month, year)
    # Get user HR data valid for month and year
    response = send_get_request(api_url, api_key, administration, "/Synergy/RequestListFiltered?filter=RequestType eq 1060015 and ResourceID eq #{original_id}")
    hr_data = response["Results"]
    valid_hr_data = hr_data
      .select do |item|
        start_date = Date.parse(item["StartDate"])
        (start_date.year < year) || (start_date.year == year && start_date.month <= month)
      end
      .sort_by { |item| Date.parse(item["StartDate"]) }
      .last    
  end

  def unbillable_work_project_numbers
    [
      "CERIOS_UREN_INTERN",
      "AANVRAAG WBSO 2022",
      "BD_TALEERGANG_BONUS",
      "BD_UREN",
      "BD_UREN_BONUS",
      "CISO",
      "COMPETENCE_UREN",
      "COMPETENCE_UREN.001",
      "CONTACTLISTS",
      "DIRECTIE_001",
      "DIRECTIE_002.001",
      "DIRECTIE_003.001",
      "DIRECTIE_004.001",
      "DOCENT ACADEMY",
      "EXACT_IMPL",
      "EXACT_IMPL.001",
      "HR_001",
      "HR_002.001",
      "HR_003.001",
      "HR_004.001",
      "HR_SALARISSHEETS",
      "JOSF",
      "KANTOOR_FULLTIME",
      "KANTOOR_PARTTIME",
      "ONTW_ATP",
      "OPERATIONS_UREN",
      "OR_INTERN",
      "SHAREPOINT_BEHEER",
      "TRAINING_OWNER",
      "UNIT LEAD UREN",
      "WBSO - COLLABORATION",
      "WBSO - ITAI",
      "WBSO- RESILIENCE",
      "LEEGLOOP",
      "ZIEK_GED_HERST",
      "ACADEMY", 
      "ACADEMY_EIGEN_BNS", 
      "ACADEMY_EIGEN_NBNS", 
      "ACADEMY_WT", 
      "ACADEMY_WT_LL"
    ]
  end
end