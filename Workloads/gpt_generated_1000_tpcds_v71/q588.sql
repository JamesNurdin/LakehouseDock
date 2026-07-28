WITH
  store_agg AS (
    SELECT
      d.d_date AS sale_date,
      s.s_store_name AS channel,
      SUM(ss.ss_net_paid) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND EXISTS (
        SELECT 1 FROM promotion p
        WHERE p.p_start_date_sk <= d.d_date_sk
          AND p.p_end_date_sk >= d.d_date_sk
      )
    GROUP BY d.d_date, s.s_store_name
  ),
  web_agg AS (
    SELECT
      d.d_date AS sale_date,
      w.web_name AS channel,
      SUM(ws.ws_net_paid) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND w.web_name IS NOT NULL
    GROUP BY d.d_date, w.web_name
  ),
  avg_sales AS (
    SELECT AVG(ss_net_paid) AS avg_sales FROM store_sales
  )
SELECT
  ca.sale_date,
  ca.channel,
  ca.total_sales,
  ca.total_profit,
  CASE WHEN ca.total_sales > (SELECT avg_sales FROM avg_sales) THEN 'Above Avg' ELSE 'Below Avg' END AS sales_category
FROM (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM web_agg
) ca
ORDER BY ca.total_sales DESC
LIMIT 100
