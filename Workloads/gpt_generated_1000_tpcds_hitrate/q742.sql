WITH
  cust_no_return AS (
    SELECT c_customer_id FROM (
      SELECT cu.c_customer_id
      FROM catalog_sales cs
      JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    )
    EXCEPT
    SELECT cu.c_customer_id
    FROM store_returns sr
    JOIN customer cu ON sr.sr_customer_sk = cu.c_customer_sk
  ),
  catalog_data AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_ship_date_sk,
      cs.cs_bill_customer_sk,
      cs.cs_quantity,
      cs.cs_sales_price,
      cs.cs_net_paid,
      cs.cs_promo_sk,
      cp.cp_department,
      cp.cp_description,
      sm.sm_type,
      p.p_promo_name,
      d.d_year,
      cu.c_first_name,
      cu.c_last_name,
      ca.ca_state,
      hd.hd_income_band_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cp.cp_department = 'Electronics'
      AND sm.sm_type = 'AIR'
      AND p.p_discount_active = 'Y'
      AND hd.hd_income_band_sk >= 5
  ),
  store_data AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_ticket_number,
      ss.ss_customer_sk,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_net_paid,
      ss.ss_promo_sk,
      d.d_year,
      cu.c_first_name,
      cu.c_last_name,
      ca.ca_state,
      hd.hd_income_band_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer cu ON ss.ss_customer_sk = cu.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'TX'
      AND hd.hd_income_band_sk BETWEEN 4 AND 12
  ),
  return_data AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      d.d_year,
      r.r_reason_desc,
      cu.c_first_name,
      cu.c_last_name,
      ca.ca_state,
      hd.hd_income_band_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer cu ON sr.sr_customer_sk = cu.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%price%'
      AND ca.ca_state = 'TX'
  ),
  web_data AS (
    SELECT
      wp.wp_web_page_id,
      wp.wp_url,
      wp.wp_type,
      ws.web_name,
      d.d_year,
      cu.c_first_name,
      cu.c_last_name
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN customer cu ON wp.wp_customer_sk = cu.c_customer_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.web_name = 'ShoppingSite'
      AND wp.wp_type = 'CONTENT'
  )
SELECT
  COALESCE(sd.c_first_name, rd.c_first_name) AS first_name,
  COALESCE(sd.c_last_name, rd.c_last_name) AS last_name,
  COALESCE(sd.ca_state, rd.ca_state) AS state,
  cd.cp_department,
  cd.cp_description,
  cd.d_year,
  SUM(cd.cs_quantity) AS total_quantity,
  SUM(cd.cs_sales_price * cd.cs_quantity) AS total_sales_amount,
  CASE
    WHEN sd.ss_net_paid IS NULL THEN rd.sr_return_amt
    ELSE sd.ss_net_paid
  END AS net_amount,
  ROW_NUMBER() OVER (PARTITION BY cd.d_year ORDER BY SUM(cd.cs_sales_price * cd.cs_quantity) DESC) AS sales_rank,
  (SELECT COUNT(*) FROM cust_no_return) AS customers_without_return
FROM store_data sd
FULL OUTER JOIN return_data rd ON sd.ss_ticket_number = rd.sr_ticket_number
LEFT JOIN catalog_data cd ON cd.cs_bill_customer_sk = sd.ss_customer_sk
LEFT JOIN web_data wd ON wd.d_year = sd.d_year
WHERE cd.cp_department IS NOT NULL
  AND cd.sm_type = 'AIR'
  AND cd.hd_income_band_sk BETWEEN 5 AND 10
  AND wd.web_name = 'ShoppingSite'
  AND cd.p_promo_name IS NOT NULL
  AND cd.cs_quantity > 0
  AND NOT EXISTS (
    SELECT 1
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = sd.ss_customer_sk
      AND cs2.cs_quantity > 50
  )
GROUP BY
  COALESCE(sd.c_first_name, rd.c_first_name),
  COALESCE(sd.c_last_name, rd.c_last_name),
  COALESCE(sd.ca_state, rd.ca_state),
  cd.cp_department,
  cd.cp_description,
  cd.d_year,
  sd.ss_net_paid,
  rd.sr_return_amt,
  wd.web_name
ORDER BY sales_rank ASC, total_sales_amount DESC
LIMIT 100
