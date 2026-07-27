WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        d.d_date,
        d.d_day_name,
        cp.cp_department,
        cp.cp_description,
        cp.cp_type,
        regexp_extract(cp.cp_description, '(\\d+)', 1) AS extracted_number,
        CASE
            WHEN ws.ws_net_profit > 1000 THEN 'HIGH'
            WHEN ws.ws_net_profit > 0  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_description, '\\d{3,}')
      AND cp.cp_type LIKE '%PROMO%'
),
agg AS (
    SELECT
        cp_department,
        d_day_name,
        COUNT(DISTINCT ws_order_number)                AS distinct_orders,
        SUM(ws_net_profit)                            AS total_profit,
        AVG(ws_ext_sales_price)                       AS avg_sales_price,
        SUM(CASE WHEN profit_category = 'HIGH' THEN ws_net_profit ELSE 0 END) AS high_profit_sum
    FROM base
    GROUP BY cp_department, d_day_name
)
SELECT
    cp_department,
    d_day_name,
    concat(cp_department, ':', d_day_name)          AS dept_day,
    distinct_orders,
    total_profit,
    avg_sales_price,
    high_profit_sum,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 100
