WITH
  store_agg AS (
    SELECT
      'store' AS channel,
      s.s_state AS state,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM tpcds.store_sales ss
    JOIN tpcds.store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE s.s_state IS NOT NULL
    GROUP BY GROUPING SETS ((s.s_state), ())
  ),
  web_agg AS (
    SELECT
      'web' AS channel,
      ca.ca_state AS state,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM tpcds.web_sales ws
    JOIN tpcds.customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IS NOT NULL
    GROUP BY GROUPING SETS ((ca.ca_state), ())
  )
SELECT
  channel,
  COALESCE(state, 'ALL') AS state,
  SUM(total_sales) AS total_sales,
  SUM(total_profit) AS total_profit,
  SUM(distinct_customers) AS distinct_customers,
  CASE WHEN SUM(total_sales) > 200000 THEN 'High' ELSE 'Low' END AS sales_category
FROM (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
) AS combined
GROUP BY ROLLUP (channel, state)
HAVING SUM(total_sales) > 50000
ORDER BY total_sales DESC
LIMIT 100
