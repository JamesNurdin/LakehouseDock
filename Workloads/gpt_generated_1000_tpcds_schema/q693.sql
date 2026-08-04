WITH
  store_perf AS (
    SELECT
      s.s_store_id,
      d.d_year,
      SUM(ss.ss_net_profit) AS total_profit,
      CASE
        WHEN SUM(ss.ss_net_profit) > (
          SELECT AVG(ss2.ss_net_profit)
          FROM store_sales ss2
        ) THEN 'above_avg'
        ELSE 'below_avg'
      END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, d.d_year
    HAVING SUM(ss.ss_net_profit) > 0
  ),
  website_perf AS (
    SELECT
      w.web_site_id,
      d.d_year,
      SUM(ws.ws_net_profit) AS total_profit,
      CASE
        WHEN SUM(ws.ws_net_profit) > (
          SELECT AVG(ws2.ws_net_profit)
          FROM web_sales ws2
        ) THEN 'above_avg'
        ELSE 'below_avg'
      END AS profit_category
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY w.web_site_id, d.d_year
    HAVING SUM(ws.ws_net_profit) > 0
  ),
  intersect_set AS (
    SELECT d_year AS year, profit_category
    FROM store_perf
    INTERSECT
    SELECT d_year AS year, profit_category
    FROM website_perf
  ),
  final_set AS (
    SELECT year, profit_category
    FROM intersect_set
    EXCEPT
    SELECT d_year AS year, profit_category
    FROM store_perf
    WHERE profit_category = 'below_avg'
  )
SELECT year, profit_category
FROM final_set
ORDER BY year DESC, profit_category
