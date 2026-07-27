WITH store_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk
          WHERE d2.d_year = d.d_year
            AND d2.d_month_seq = d.d_month_seq
      )
    GROUP BY d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk
          WHERE d2.d_year = d.d_year
            AND d2.d_month_seq = d.d_month_seq
      )
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    combined.year,
    combined.month,
    combined.channel,
    combined.total_sales,
    combined.total_profit,
    combined.profit_sign,
    combined.avg_monthly_profit
FROM (
    SELECT
        sm.year,
        sm.month,
        sm.channel,
        sm.total_sales,
        sm.total_profit,
        sm.profit_sign,
        (
            SELECT AVG(mp.total_profit)
            FROM (
                SELECT total_profit FROM store_monthly
                UNION ALL
                SELECT total_profit FROM web_monthly
            ) AS mp
        ) AS avg_monthly_profit
    FROM store_monthly sm
    UNION ALL
    SELECT
        wm.year,
        wm.month,
        wm.channel,
        wm.total_sales,
        wm.total_profit,
        wm.profit_sign,
        (
            SELECT AVG(mp.total_profit)
            FROM (
                SELECT total_profit FROM store_monthly
                UNION ALL
                SELECT total_profit FROM web_monthly
            ) AS mp
        ) AS avg_monthly_profit
    FROM web_monthly wm
) AS combined
ORDER BY combined.year, combined.month, combined.channel
LIMIT 100
