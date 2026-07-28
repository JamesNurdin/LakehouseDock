WITH store_daily AS (
    SELECT d.d_date AS sales_date,
           'store' AS channel,
           SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 1998
      AND s.s_number_employees > 150
    GROUP BY d.d_date
),
web_daily AS (
    SELECT d.d_date AS sales_date,
           'web' AS channel,
           SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 1998
      AND w.web_county = 'Maverick County'
      AND EXISTS (
          SELECT 1 FROM reason r WHERE r.r_reason_sk = ws.ws_ship_mode_sk
      )
    GROUP BY d.d_date
)
SELECT sales_date,
       channel,
       total_net_paid_inc_tax
FROM (
    SELECT * FROM store_daily
    UNION ALL
    SELECT * FROM web_daily
) AS combined
ORDER BY sales_date DESC, channel
LIMIT 100
