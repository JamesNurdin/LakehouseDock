WITH store_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        'store' AS channel,
        NULL AS ship_mode,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND ss.ss_quantity > 0
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        sm.sm_type AS ship_mode,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND ws.ws_quantity > 0
      AND t.t_hour BETWEEN 9 AND 17
      AND sm.sm_type IS NOT NULL
    GROUP BY d.d_year, d.d_quarter_seq, i.i_category, sm.sm_type
)
SELECT
    year,
    quarter,
    category,
    channel,
    ship_mode,
    total_net_profit,
    total_quantity,
    total_sales,
    total_net_profit / NULLIF(total_quantity, 0) AS profit_per_unit,
    RANK() OVER (PARTITION BY year, quarter, channel ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        d_year AS year,
        d_quarter_seq AS quarter,
        i_category AS category,
        channel,
        ship_mode,
        total_net_profit,
        total_quantity,
        total_sales
    FROM store_agg
    UNION ALL
    SELECT
        d_year AS year,
        d_quarter_seq AS quarter,
        i_category AS category,
        channel,
        ship_mode,
        total_net_profit,
        total_quantity,
        total_sales
    FROM web_agg
) t
ORDER BY year, quarter, channel, profit_rank
LIMIT 100
