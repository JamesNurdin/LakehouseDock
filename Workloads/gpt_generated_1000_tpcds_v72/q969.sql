WITH store_agg AS (
    SELECT
        'store' AS sales_channel,
        hd.hd_buy_potential,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_net_paid > 100
      AND hd.hd_dep_count > 2
      AND hd.hd_buy_potential <> 'Unknown'
    GROUP BY GROUPING SETS ((hd.hd_buy_potential), ())
),
web_agg AS (
    SELECT
        'web' AS sales_channel,
        hd.hd_buy_potential,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_net_paid > 100
      AND w.web_country = 'United States'
      AND hd.hd_buy_potential <> 'Unknown'
    GROUP BY GROUPING SETS ((hd.hd_buy_potential), ())
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    sales_channel,
    COALESCE(hd_buy_potential, 'ALL') AS buy_potential,
    total_net_paid,
    total_net_profit,
    (SELECT AVG(total_net_profit) FROM combined) AS overall_avg_profit
FROM combined
ORDER BY sales_channel, buy_potential
LIMIT 100
