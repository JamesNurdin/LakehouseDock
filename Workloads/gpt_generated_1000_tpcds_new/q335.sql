WITH
  agg_sales AS (
    SELECT
      d.d_year AS year,
      ca.ca_state AS state,
      ws.web_name AS website,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_zip LIKE '8%'
      AND ss.ss_ext_sales_price > 1000
      AND ws.web_gmt_offset BETWEEN -5 AND 5
    GROUP BY d.d_year, ca.ca_state, ws.web_name
  ),
  high_sales AS (
    SELECT state, website FROM agg_sales WHERE total_sales > 50000
  ),
  high_profit AS (
    SELECT state, website FROM agg_sales WHERE total_profit > 10000
  ),
  intersect_keys AS (
    SELECT state, website FROM high_sales
    INTERSECT
    SELECT state, website FROM high_profit
  ),
  final_agg AS (
    SELECT
      a.year,
      a.state,
      a.website,
      a.total_sales,
      a.total_profit,
      a.txn_count,
      CASE WHEN a.total_sales > (SELECT AVG(total_sales) FROM agg_sales) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS sales_category,
      ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS rn
    FROM agg_sales a
    WHERE (a.state, a.website) IN (SELECT state, website FROM intersect_keys)
  )
SELECT
  year,
  state,
  website,
  total_sales,
  total_profit,
  txn_count,
  sales_category,
  rn
FROM final_agg
ORDER BY total_sales DESC
LIMIT 100
