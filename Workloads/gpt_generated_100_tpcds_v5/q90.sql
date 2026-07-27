WITH sales_summary AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    cd.cd_gender,
    td.t_shift,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS avg_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
    MIN(ss.ss_sold_date_sk) AS first_sold_date_sk,
    MAX(ss.ss_sold_date_sk) AS last_sold_date_sk
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE s.s_gmt_offset = -6.00
    AND cd.cd_marital_status = 'M'
    AND td.t_shift = 'first'
    AND EXISTS (
      SELECT 1
      FROM customer_address ca
      WHERE ca.ca_address_sk = ss.ss_addr_sk
        AND ca.ca_state = 'CA'
        AND ca.ca_gmt_offset = -6.00
    )
  GROUP BY s.s_store_id, s.s_store_name, cd.cd_gender, td.t_shift
)
SELECT
  s_store_id,
  s_store_name,
  cd_gender,
  t_shift,
  total_sales,
  avg_profit,
  order_cnt,
  first_sold_date_sk,
  last_sold_date_sk
FROM sales_summary
ORDER BY total_sales DESC
LIMIT 100
