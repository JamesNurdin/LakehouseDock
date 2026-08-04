WITH joined_data AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_birth_country,
    c.c_birth_year,
    hd.hd_income_band_sk,
    hd.hd_dep_count,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    ss.ss_coupon_amt,
    cr.cr_return_amount,
    cr.cr_returned_date_sk,
    wp.wp_type,
    wp.wp_url
  FROM tpcds.store_sales ss
  JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
)
SELECT
  jd.c_customer_id,
  jd.c_birth_country,
  jd.c_birth_year,
  jd.hd_income_band_sk,
  jd.ss_net_paid,
  jd.cr_return_amount,
  CASE WHEN jd.hd_income_band_sk >= 10 THEN 'High' ELSE 'Medium' END AS income_category,
  attr AS page_attribute,
  RANK() OVER (PARTITION BY jd.c_customer_id ORDER BY jd.ss_net_paid DESC) AS profit_rank,
  SUM(jd.ss_net_paid) OVER (
    PARTITION BY jd.c_customer_id
    ORDER BY jd.ss_ticket_number
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_net_paid
FROM joined_data jd
CROSS JOIN UNNEST(ARRAY[jd.wp_type, jd.wp_url]) AS t (attr)
WHERE jd.c_birth_country IN ('SWITZERLAND', 'UKRAINE')
  AND jd.hd_income_band_sk > 5
  AND jd.ss_coupon_amt > 500
  AND jd.cr_returned_date_sk BETWEEN 2451000 AND 2451100
  AND jd.wp_type IS NOT NULL
ORDER BY jd.c_customer_id, profit_rank
OFFSET 0 FETCH NEXT 100 ROWS ONLY
