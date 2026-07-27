WITH sales_agg AS (
   SELECT
      ca_city,
      ca_state,
      concat(ca_city, ', ', ca_state) AS city_state,
      sum(ss_ext_sales_price) AS total_sales,
      sum(ss_net_profit) AS total_profit,
      count(*) AS sales_cnt
   FROM store_sales
   JOIN customer_address ON store_sales.ss_addr_sk = customer_address.ca_address_sk
   JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
   WHERE regexp_like(ca_street_name, '^.*Washington.*$')
     AND ca_zip LIKE '85%'
   GROUP BY ca_city, ca_state, concat(ca_city, ', ', ca_state)
   HAVING sum(ss_ext_sales_price) > (
      SELECT avg(ss_ext_sales_price) FROM store_sales
   )
),
returns_agg AS (
   SELECT
      ca_city,
      ca_state,
      concat(ca_city, ', ', ca_state) AS city_state,
      sum(wr_return_amt) AS total_returns,
      sum(wr_net_loss) AS total_loss,
      count(*) AS returns_cnt
   FROM web_returns
   JOIN customer_address ON web_returns.wr_refunded_addr_sk = customer_address.ca_address_sk
   JOIN customer_demographics ON web_returns.wr_refunded_cdemo_sk = customer_demographics.cd_demo_sk
   WHERE regexp_like(ca_street_name, '^.*Washington.*$')
     AND ca_zip LIKE '85%'
   GROUP BY ca_city, ca_state, concat(ca_city, ', ', ca_state)
   HAVING sum(wr_return_amt) > 0
)
SELECT
   city_state,
   total_sales,
   total_profit,
   sales_cnt,
   NULL AS total_returns,
   NULL AS total_loss,
   'sales' AS src
FROM sales_agg
UNION ALL
SELECT
   city_state,
   NULL AS total_sales,
   NULL AS total_profit,
   NULL AS sales_cnt,
   total_returns,
   total_loss,
   'returns' AS src
FROM returns_agg
ORDER BY city_state, src
LIMIT 100
