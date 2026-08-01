WITH
  ss_agg AS (
    SELECT
      ss.ss_addr_sk,
      SUM(ss.ss_ext_sales_price)               AS sum_sales,
      AVG(ss.ss_wholesale_cost)                AS avg_wholesale_cost,
      COUNT(*)                                 AS cnt_sales,
      MIN(ss.ss_ext_sales_price)               AS min_sales,
      MAX(ss.ss_ext_sales_price)               AS max_sales
    FROM tpcds.store_sales ss
      TABLESAMPLE BERNOULLI (10)               -- sample 10% of rows
    WHERE ss.ss_quantity BETWEEN 1 AND 5
      AND ss.ss_ext_sales_price > 500
      AND ss.ss_net_profit > 0
      AND ss.ss_wholesale_cost BETWEEN 10 AND 100
      AND ss.ss_ext_discount_amt < 200
    GROUP BY ss.ss_addr_sk
  ),
  addr_ca AS (
    SELECT *
    FROM tpcds.customer_address
    WHERE ca_state = 'CA'
      AND ca_location_type = 'apartment'
      AND ca_zip LIKE '9%'
      AND ca_gmt_offset BETWEEN -5.00 AND 5.00
      AND ca_city = 'Los Angeles'
  ),
  anti_addr AS (
    SELECT ca_address_sk
    FROM tpcds.customer_address
    WHERE ca_country = 'USA' AND ca_location_type = 'condo'
  ),
  unioned AS (
    SELECT
      ca.ca_state,
      ca.ca_city,
      ss.sum_sales,
      ss.cnt_sales,
      ss.avg_wholesale_cost,
      ss.min_sales,
      ss.max_sales
    FROM ss_agg ss
    JOIN addr_ca ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE NOT EXISTS (
      SELECT 1 FROM anti_addr a WHERE a.ca_address_sk = ca.ca_address_sk
    )
    UNION DISTINCT
    SELECT
      ca2.ca_state,
      ca2.ca_city,
      ss2.sum_sales,
      ss2.cnt_sales,
      ss2.avg_wholesale_cost,
      ss2.min_sales,
      ss2.max_sales
    FROM ss_agg ss2
    JOIN (
      SELECT *
      FROM tpcds.customer_address
      WHERE ca_state = 'NY'
        AND ca_location_type = 'single family'
        AND ca_zip LIKE '1%'
        AND ca_gmt_offset BETWEEN -5.00 AND 5.00
        AND ca_city = 'New York'
    ) ca2 ON ss2.ss_addr_sk = ca2.ca_address_sk
    WHERE NOT EXISTS (
      SELECT 1 FROM anti_addr a2 WHERE a2.ca_address_sk = ca2.ca_address_sk
    )
  ),
  rollup_agg AS (
    SELECT
      ca_state,
      ca_city,
      SUM(sum_sales)           AS total_sales,
      SUM(cnt_sales)           AS total_transactions,
      AVG(avg_wholesale_cost)  AS avg_wholesale,
      MIN(min_sales)           AS min_sales,
      MAX(max_sales)           AS max_sales
    FROM unioned
    GROUP BY ROLLUP (ca_state, ca_city)
    HAVING SUM(sum_sales) > 10000
  )
SELECT
  ca_state,
  ca_city,
  total_sales,
  total_transactions,
  avg_wholesale,
  min_sales,
  max_sales,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS state_sales_rank
FROM rollup_agg
ORDER BY total_sales DESC
LIMIT 100
