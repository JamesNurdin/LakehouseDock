WITH
  bill_sales AS (
    SELECT
      ca.ca_state,
      SUM(cs.cs_ext_sales_price) AS total_ext_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sales_price > 20
      AND ca.ca_gmt_offset BETWEEN -9 AND -6
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY ca.ca_state
  ),
  ship_sales AS (
    SELECT
      ca.ca_state,
      SUM(cs.cs_ext_sales_price) AS total_ext_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_ship_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sales_price > 20
      AND ca.ca_gmt_offset BETWEEN -9 AND -6
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY ca.ca_state
  ),
  combined AS (
    SELECT ca_state, total_ext_sales, total_profit, sales_cnt FROM bill_sales
    UNION ALL
    SELECT ca_state, total_ext_sales, total_profit, sales_cnt FROM ship_sales
  ),
  aggregated AS (
    SELECT
      ca_state,
      SUM(total_ext_sales) AS sum_ext_sales,
      SUM(total_profit) AS sum_profit,
      SUM(sales_cnt) AS sum_cnt,
      AVG(total_profit) AS avg_profit_per_batch
    FROM combined
    GROUP BY ca_state
  )
SELECT DISTINCT
  a.ca_state,
  a.sum_ext_sales,
  a.sum_profit,
  a.sum_cnt,
  a.avg_profit_per_batch,
  ROW_NUMBER() OVER (ORDER BY a.sum_ext_sales DESC) AS sales_rank
FROM aggregated a
WHERE NOT EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_state = a.ca_state
          AND ca2.ca_city = 'Los Angeles'
      )
  AND EXISTS (
        SELECT 1
        FROM customer_address ca3
        WHERE ca3.ca_state = a.ca_state
          AND ca3.ca_zip LIKE '9%'
      )
  AND a.sum_ext_sales > 10000
  AND a.sum_profit > 5000
ORDER BY sales_rank
