WITH store_agg AS (
    SELECT
        s.s_store_name AS channel,
        CAST(d.d_year AS VARCHAR) || '-' || LPAD(CAST(d.d_moy AS VARCHAR), 2, '0') AS period,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_name, d.d_year, d.d_moy
    HAVING SUM(ss.ss_ext_sales_price) > 5000
),
web_agg AS (
    SELECT
        sm.sm_type AS channel,
        CAST(d.d_year AS VARCHAR) || '-' || LPAD(CAST(d.d_moy AS VARCHAR), 2, '0') AS period,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
    GROUP BY sm.sm_type, d.d_year, d.d_moy
),
combined AS (
    SELECT DISTINCT channel, period, total_sales, total_profit FROM store_agg
    UNION ALL
    SELECT DISTINCT channel, period, total_sales, total_profit FROM web_agg
),
ranked AS (
    SELECT
        channel,
        period,
        total_sales,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY period ORDER BY total_sales DESC) AS sales_rank
    FROM combined
    WHERE total_sales > 10000
)
SELECT
    channel,
    period,
    total_sales,
    total_profit,
    sales_rank
FROM ranked
ORDER BY period, sales_rank
LIMIT 100
