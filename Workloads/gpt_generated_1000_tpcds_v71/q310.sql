WITH sales_data AS (
  SELECT
    s.s_store_sk,
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_suite_number,
    s.s_hours,
    cd.cd_marital_status,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_coupon_amt
  FROM store_sales ss
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  WHERE
    regexp_like(s.s_suite_number, '^Suite [0-9]+$')
    AND s.s_city LIKE '%York%'
    AND regexp_like(s.s_hours, '^[0-9]{2}:[0-9]{2}-[0-9]{2}:[0-9]{2}$')
    AND cd.cd_marital_status = 'M'
    AND cd.cd_dep_college_count >= 2
)
SELECT
  sd.s_store_id,
  sd.s_city,
  sd.s_state,
  CONCAT(sd.s_city, ', ', sd.s_state) AS location,
  sd.cd_marital_status,
  SUM(sd.ss_ext_sales_price) AS total_sales,
  AVG(sd.ss_net_profit) AS avg_profit,
  ROW_NUMBER() OVER (PARTITION BY sd.s_store_id ORDER BY SUM(sd.ss_ext_sales_price) DESC) AS sales_rank
FROM sales_data sd
WHERE NOT EXISTS (
  SELECT 1
  FROM store_sales ss2
  WHERE ss2.ss_store_sk = sd.s_store_sk
    AND ss2.ss_coupon_amt > 1000
)
GROUP BY
  sd.s_store_id,
  sd.s_city,
  sd.s_state,
  sd.cd_marital_status
HAVING
  SUM(sd.ss_ext_sales_price) > 10000
  AND AVG(sd.ss_net_profit) > 0
ORDER BY total_sales DESC
LIMIT 100
