WITH avg_profit AS (
    SELECT avg(ws_net_profit) AS avg_profit
    FROM web_sales
)

SELECT fiscal_quarter,
       total_profit,
       order_count,
       overall_avg_profit
FROM (
    SELECT d.d_fy_quarter_seq AS fiscal_quarter,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS order_count,
           (SELECT avg_profit FROM avg_profit) AS overall_avg_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_zip = '86787'
      AND ws.ws_net_profit > (SELECT avg_profit FROM avg_profit)
    GROUP BY d.d_fy_quarter_seq

    UNION ALL

    SELECT d.d_fy_quarter_seq AS fiscal_quarter,
           SUM(ws.ws_net_profit) AS total_profit,
           COUNT(*) AS order_count,
           (SELECT avg_profit FROM avg_profit) AS overall_avg_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_zip = '49532'
      AND EXISTS (
          SELECT 1
          FROM store s
          JOIN date_dim d2 ON s.s_closed_date_sk = d2.d_date_sk
          WHERE s.s_state = w.web_state
            AND d2.d_year = d.d_year
          LIMIT 1
      )
    GROUP BY d.d_fy_quarter_seq
) AS combined
ORDER BY fiscal_quarter,
         total_profit DESC
LIMIT 100
