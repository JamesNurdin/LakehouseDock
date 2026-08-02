WITH sales_data AS (
  SELECT
    s.s_store_sk AS s_store_sk,
    s.s_store_name AS s_store_name,
    d.d_year AS d_year,
    d.d_month_seq AS d_month_seq,
    d.d_quarter_seq AS d_quarter_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE
      WHEN SUM(ss.ss_ext_discount_amt) > 5000 THEN 'High Discount'
      ELSE 'Low Discount'
    END AS discount_category,
    regexp_extract(s.s_suite_number, '\\d+', 0) AS suite_number_digits,
    CONCAT(s.s_state, '-', s.s_zip) AS state_zip,
    cp.cp_description AS cp_description,
    regexp_extract(cp.cp_description, '[A-Z]{2}\\d+', 0) AS extracted_code
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_suite_number LIKE 'Suite %'
    AND regexp_like(s.s_state, '^[A-Z]{2}$')
  GROUP BY
    s.s_store_sk,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_seq,
    s.s_suite_number,
    s.s_state,
    s.s_zip,
    cp.cp_description
),
returns_data AS (
  SELECT
    s.s_store_sk AS s_store_sk,
    s.s_store_name AS s_store_name,
    d.d_year AS d_year,
    d.d_month_seq AS d_month_seq,
    d.d_quarter_seq AS d_quarter_seq,
    SUM(sr.sr_return_amt) AS total_sales,
    SUM(sr.sr_return_tax) AS total_discount,
    SUM(sr.sr_net_loss) AS total_profit,
    CASE
      WHEN SUM(sr.sr_return_amt) > 3000 THEN 'High Discount'
      ELSE 'Low Discount'
    END AS discount_category,
    regexp_extract(s.s_suite_number, '\\d+', 0) AS suite_number_digits,
    CONCAT(s.s_state, '-', s.s_zip) AS state_zip,
    cp.cp_description AS cp_description,
    regexp_extract(cp.cp_description, '[A-Z]{2}\\d+', 0) AS extracted_code
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_suite_number LIKE 'Suite %'
    AND regexp_like(s.s_state, '^[A-Z]{2}$')
  GROUP BY
    s.s_store_sk,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_seq,
    s.s_suite_number,
    s.s_state,
    s.s_zip,
    cp.cp_description
)
SELECT
  combined.s_store_sk,
  combined.s_store_name,
  combined.d_year,
  combined.d_month_seq,
  combined.d_quarter_seq,
  combined.total_sales,
  combined.total_discount,
  combined.total_profit,
  combined.discount_category,
  combined.suite_number_digits,
  combined.state_zip,
  combined.extracted_code,
  ROW_NUMBER() OVER (PARTITION BY combined.d_quarter_seq ORDER BY combined.total_sales DESC) AS sales_rank
FROM (
  SELECT
    s_store_sk,
    s_store_name,
    d_year,
    d_month_seq,
    d_quarter_seq,
    total_sales,
    total_discount,
    total_profit,
    discount_category,
    suite_number_digits,
    state_zip,
    extracted_code
  FROM sales_data
  UNION
  SELECT
    s_store_sk,
    s_store_name,
    d_year,
    d_month_seq,
    d_quarter_seq,
    total_sales,
    total_discount,
    total_profit,
    discount_category,
    suite_number_digits,
    state_zip,
    extracted_code
  FROM returns_data
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 100
