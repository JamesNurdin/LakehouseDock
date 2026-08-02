WITH avg_store_profit AS (
    SELECT avg(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)
SELECT s.s_state AS sales_state,
       sum(ss.ss_net_profit) AS total_profit,
       'Store' AS sales_channel
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND ss.ss_hdemo_sk IN (
      SELECT hd.hd_demo_sk
      FROM household_demographics hd
      JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
      WHERE ib.ib_lower_bound >= 50000
  )
GROUP BY s.s_state
HAVING sum(ss.ss_net_profit) > (SELECT avg_profit FROM avg_store_profit)
UNION
SELECT w.web_state AS sales_state,
       sum(ws.ws_net_profit) AS total_profit,
       'Web' AS sales_channel
FROM web_sales ws
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
WHERE d2.d_year = 2002
  AND ws.ws_item_sk IN (
      SELECT i.i_item_sk
      FROM item i
      WHERE i.i_current_price > 1000
  )
GROUP BY w.web_state
ORDER BY total_profit DESC
