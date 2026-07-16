SELECT s.s_store_id,
    s.s_store_name,
    s.s_floor_space,
    s.s_floor_space / 1000.0 AS floor_space_k_sqft,
    CASE 
        WHEN s.s_closed_date_sk IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS store_status,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    CONCAT(d.d_day_name, ', ', CAST(d.d_date AS varchar)) AS day_full_desc,
    CASE 
        WHEN d.d_holiday = 'N' THEN 'Holiday'
        ELSE 'Regular Day'
    END AS day_type,
    (s.s_number_employees * s.s_gmt_offset) AS employee_gmt_product
FROM store s
JOIN date_dim d
  ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 1915
  AND d.d_month_seq BETWEEN 4 AND 39
  AND s.s_state = 'MO'
