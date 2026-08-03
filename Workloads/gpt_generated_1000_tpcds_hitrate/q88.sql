WITH
  agg_sales AS (
    SELECT
      ss_customer_sk,
      ss_ticket_number,
      SUM(ss_net_paid)            AS total_net_paid,
      SUM(ss_quantity)            AS total_qty
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ss_customer_sk, ss_ticket_number
  ),
  agg_returns AS (
    SELECT
      sr_customer_sk,
      sr_ticket_number,
      SUM(sr_return_amt)          AS total_return_amt,
      SUM(sr_return_quantity)     AS total_return_qty
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY sr_customer_sk, sr_ticket_number
  ),
  small_cc AS (
    SELECT DISTINCT cc_state
    FROM call_center
    WHERE cc_state IS NOT NULL
    LIMIT 5
  )
,
  male_side AS (
    SELECT
      c.c_customer_id   AS customer_id,
      cd.cd_gender       AS gender,
      ca.ca_zip          AS zip,
      cc.cc_name         AS call_center_name,
      cp.cp_department   AS department,
      s.total_net_paid,
      r.total_return_amt,
      (s.total_net_paid - r.total_return_amt) AS net_after_returns,
      sc.cc_state        AS state,
      ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY s.total_net_paid DESC) AS gender_rank
    FROM agg_sales s
    JOIN agg_returns r
      ON s.ss_customer_sk = r.sr_customer_sk
     AND s.ss_ticket_number = r.sr_ticket_number
    JOIN customer c               ON c.c_customer_sk = s.ss_customer_sk
    JOIN customer_address ca      ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN catalog_returns cr       ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_page cp          ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN call_center cc           ON cc.cc_call_center_sk = cr.cr_call_center_sk
    CROSS JOIN small_cc sc
    WHERE c.c_birth_year >= 1960
      AND cd.cd_gender = 'M'
      AND ca.ca_zip LIKE '9%'
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
      AND cp.cp_type = 'PROMO'
  ),
  female_side AS (
    SELECT
      c.c_customer_id   AS customer_id,
      cd.cd_gender       AS gender,
      ca.ca_zip          AS zip,
      cc.cc_name         AS call_center_name,
      cp.cp_department   AS department,
      s.total_net_paid,
      r.total_return_amt,
      (s.total_net_paid - r.total_return_amt) AS net_after_returns,
      sc.cc_state        AS state,
      ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY s.total_net_paid DESC) AS gender_rank
    FROM agg_sales s
    JOIN agg_returns r
      ON s.ss_customer_sk = r.sr_customer_sk
     AND s.ss_ticket_number = r.sr_ticket_number
    JOIN customer c               ON c.c_customer_sk = s.ss_customer_sk
    JOIN customer_address ca      ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN catalog_returns cr       ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN catalog_page cp          ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN call_center cc           ON cc.cc_call_center_sk = cr.cr_call_center_sk
    CROSS JOIN small_cc sc
    WHERE c.c_birth_year >= 1970
      AND cd.cd_gender = 'F'
      AND ca.ca_zip LIKE '1%'
      AND cc.cc_gmt_offset BETWEEN -3.00 AND 3.00
      AND cp.cp_type = 'NON_PROMO'
  ),
  male_filtered AS (
    SELECT *
    FROM male_side
    WHERE gender_rank <= 5
  ),
  female_filtered AS (
    SELECT *
    FROM female_side
    WHERE gender_rank <= 5
  ),
  combined AS (
    SELECT customer_id, gender, zip, call_center_name, department,
           total_net_paid, total_return_amt, net_after_returns, state, gender_rank
    FROM male_filtered
    UNION DISTINCT
    SELECT customer_id, gender, zip, call_center_name, department,
           total_net_paid, total_return_amt, net_after_returns, state, gender_rank
    FROM female_filtered
  )
SELECT
  customer_id,
  gender,
  zip,
  call_center_name,
  department,
  total_net_paid,
  total_return_amt,
  net_after_returns,
  state,
  gender_rank
FROM combined
ORDER BY net_after_returns DESC
LIMIT 100
