WITH cons AS (  
	SELECT tmp.candidate_id
		, string_agg(ua."name", ',') AS candidate_onwers
		, string_agg(substring(ua.first_name, 1,1) || substring(ua.last_name, 1,1), ',') AS consultant_code
	FROM 
	(
		SELECT candidate_id
			, UNNEST(candidate_owner_ids) AS owner_id 
		FROM candidate_extension ce  
	) tmp 
	JOIN user_account ua ON ua.id = tmp.owner_id
	GROUP BY tmp.candidate_id
)
SELECT UPPER(COALESCE(SUBSTRING(usr_br.division,1,3), 'CE')) AS "Employer Ref"
	, '' "Employment Sequence No"
	, c.last_name "Surname"
	, c.first_name "First forename"
	, c.middle_name "Second forename"
	, '' "Third forename"
	, c.gender_title "Title"
	, cl.address_line1 "Address line 1"
	, cl.address_line2 "Address line 2"
	, cl.district "Address line 3"
	, cl.city "Address line 4"
	, cl.state "Address line 5"
	, cl.post_code "Post code"
	, ctr.system_name AS "Country"
	, c.phone2 AS "Telephone number"
	, CASE c.male WHEN 1 THEN 'M'
		WHEN 0 THEN 'F'
		END AS "Gender"
	, c.date_of_birth "Date of birth"
	, CASE c.maritalstatus WHEN 1 THEN 'Single'
		WHEN 2 THEN 'Married'
		WHEN 3 THEN 'Divorced'
		WHEN 4 THEN 'Widowed'
		WHEN 5 THEN 'Separated'
		WHEN 6 THEN 'Unkown'
		WHEN 7 THEN 'Unmarried'
		END AS "Marital status"
	,'' AS "Previous surname"
	,'' AS "Nationality"
	,'' AS "Citizenship"
	,'' AS "Passport held"
	,'' AS "Next of kin"
	,'' AS "Next of kin relation"
	,'' AS "Next of kin addr 1"
	,'' AS "Next of kin addr 2"
	,'' AS "Next of kin addr 3"
	,'' AS "Next of kin addr 4"
	,'' AS "Next of kin addr 5"
	,'' AS "Next of kin postcode"
	,'' AS "Next of kin country"
	,'' AS "Next of kin telephne"
	,'' AS "Emergency contact"
	,'' AS "Emergency cont tel"
	,'' AS "Last address line 1"
	,'' AS "Last address line 2"
	,'' AS "Last address line 3"
	,'' AS "Last address line 4"
	,'' AS "Last address line 5"
	,'' AS "Last post code"
	,'' AS "Last country"
	,'' AS "Date of address change"
	, opi.start_date AS "Start date"
	,'' AS "Leaving Date"
	,'' AS "Leaving Code"
	,'' AS "User index"
	,'' AS "Personnel notes"
	,'' AS "Work Telephone"
	,'' AS "Work Fax"
	,'' AS "Mobile Telephone"
	, c.email "Email Address"
	, cfv.field_value AS "NI number"
	, cfv2.field_value AS "NI table letter"
	, '' AS "Contracted out"
	, 'BR' AS "PAYE code"
	, cfv3.field_value AS "Pay method"
	, cfv4.field_value AS "Bank1 sort code"
	, cfv5.field_value AS "Bank1 account number"
	, cfv6.field_value AS "Bank1 account name"
	,'' AS "Bank1 account type"
	,'' AS "Bank1 Ref"
	,'' AS "Build society1 name"
	,'' AS "Build society1 num"
	,'' AS "Secondary Pay method"
	,'' AS "Bank2 sort code"
	,'' AS "Bank2 account number"
	,'' AS "Bank2 account name"
	,'' AS "Bank2 account type"
	,'' AS "Bank2 Ref"
	,'' AS "Build society2 name"
	,'' AS "Build society2 num"
	,'' AS "Payroll notes"
	,'' AS "Student"
	,'' AS "Analysis Code"
	,'' AS "Tax Regime"
	, UPPER(COALESCE('C'||SUBSTRING(usr_br.division,1,1), 'CE')) "Division"
	,'FS' AS "Department"
	,'' AS "Job Category"
	,'' AS "WTD Waiver Signed"
	, 'P' AS "Employment status"
	,'' AS "Business Name"
	,'' AS "Partner Name 1"
	,'' AS "Partner DOB 1"
	,'' AS "Partner NI 1"
	,'' AS "Partner Name 2"
	,'' AS "Partner DOB 2"
	,'' AS "Partner NI 2"
	,'' AS "Partner Name 3"
	,'' AS "Partner DOB 3"
	,'' AS "Partner NI 3"
	,'' AS "Effective From"
	,'' AS "Effective To"
	,'' AS "CIS Photo Matches"
	,'' AS "CIS Signature Check"
	,'' AS "CIS Certificate Number"
	,'' AS "Incorporation Date"
	,'' AS "Company Reg No"
	,'' AS "VAT Number"
	,'' AS "CIS Type"
	,'' AS "CIS Card Number"
	,'' AS "CIS Start Date"
	,'' AS "CIS Expiry Date"
	,'' AS "CIS Issued To"
	,'' AS "CIS Acting For"
	,'' AS "CIS Trading As"
	,'' AS "Schedule D Number-NOT USED"
	,'' AS "Trade Notes"
	,'' AS "Trade address 1"
	,'' AS "Trade address 2"
	,'' AS "Trade address 3"
	,'' AS "Trade address 4"
	,'' AS "Trade address 5"
	,'' AS "Trade post code"
	,'' AS "Trade country"
	,'' AS "Self Billing ?"
	,'' AS "Workers Logo"
	,'' AS "Purchase Ledger Acc No."
	,'' AS "Currency Code"
	,'' AS "Contractor VAT Rate"
	, cons.candidate_onwers
	, cons.consultant_code "Consultant Code"
	,'' AS "Supplier Ref"
	,'' AS "AWR Type"
	,'' AS "Excluded_Reg_Pension"
	,'' AS "Passport Number"
	,'' AS "Starting Dec Category"
	,'' AS "Student Loan"
	,'' AS "Starting Dec By Employee"
	,'' AS "Opt In"
	,'' AS "Opt In Notice Received"
	,'' AS "Email Address 2"
	,'' AS "Expat"
	,'' AS "EIR Engagement Status"
	,'' AS "UTR Non CIS"
	,'' AS "CIS Unique Tax Reference"
	,'' AS "CIS Legal Status"
	,'' AS "Starting Dec Student Loan Plan Type"
	,'' AS "Apprentice"
	,'' AS "Student Finished Studies"
	,'' AS "Student Loan Paid Externally"
	,'' AS "eP45 Print Method"
FROM candidate c 
JOIN position_candidate pc ON pc.candidate_id = c.id 
LEFT JOIN offer o ON o.position_candidate_id = pc.id 
LEFT JOIN offer_personal_info opi ON opi.offer_id = o.id
LEFT JOIN (
	SELECT user_id
		, string_agg(tg.name, ', ') AS division 
	FROM user_primary_brand upb
	LEFT JOIN team_group tg ON tg.id = upb.primary_brand_id
			AND tg.group_type = 'BRANCH'
	GROUP BY user_id
) usr_br ON usr_br.user_id = c.user_account_id  
LEFT JOIN common_location cl ON cl.id = c.current_location_id 
LEFT JOIN country ctr ON ctr.code = cl.country_code 
LEFT JOIN configurable_form_core_field_value cfv ON cfv.entity_id = c.id AND cfv.field_id = 5 -- nsn
LEFT JOIN configurable_form_core_field_value cfv2 ON cfv2.entity_id = c.id AND cfv2.field_id = 6 -- nsn letter
LEFT JOIN configurable_form_core_field_value cfv3 ON cfv3.entity_id = c.id AND cfv3.field_id = 12 --  payment METHOD
LEFT JOIN configurable_form_core_field_value cfv4 ON cfv4.entity_id = c.id AND cfv4.field_id = 19 --  bank soft code
LEFT JOIN configurable_form_core_field_value cfv5 ON cfv5.entity_id = c.id AND cfv5.field_id = 16 --  bank acc no
LEFT JOIN configurable_form_core_field_value cfv6 ON cfv6.entity_id = c.id AND cfv6.field_id = 17 --  bank acc name
LEFT JOIN cons ON cons.candidate_id = c.id 