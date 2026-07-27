WITH sales_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        d.d_day_name,
        d.d_date,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        w.w_country,
        w.w_street_number
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        -- Only weekend sales (Saturday or Sunday)
        regexp_like(d.d_day_name, '^Sat|^Sun')
        -- Warehouse street numbers that start with '6'
        AND w.w_street_number LIKE '6%'
)
SELECT
    concat(sj.w_city, ', ', sj.w_state) AS location,
    sj.w_country,
    regexp_extract(sj.w_warehouse_name, '(\\d+)', 1) AS warehouse_code,
    substring(sj.w_city, 1, 3) AS city_prefix,
    COUNT(sj.ws_order_number) AS orders_count,
    SUM(sj.ws_net_profit) AS total_net_profit
FROM sales_join sj
GROUP BY
    concat(sj.w_city, ', ', sj.w_state),
    sj.w_country,
    regexp_extract(sj.w_warehouse_name, '(\\d+)', 1),
    substring(sj.w_city, 1, 3)
ORDER BY total_net_profit DESC
