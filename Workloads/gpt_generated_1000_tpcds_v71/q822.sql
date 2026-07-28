/* Goal: Summarize web sales net profit by year, shipping mode and warehouse, categorize profit tiers, rank shipping modes, and demonstrate string pattern matching, extraction, and a scalar subquery for overall average profit. */
WITH sold AS (
    SELECT
        ws_order_number,
        ws_ext_sales_price,
        ws_net_profit,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        ws_sold_date_sk,
        ws_sold_time_sk
    FROM web_sales
    WHERE ws_ext_sales_price > 1000
),
joined AS (
    SELECT
        s.ws_order_number,
        s.ws_net_profit,
        s.ws_ext_sales_price,
        d.d_year,
        t.t_hour,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_city,
        w.w_street_type,
        CASE
            WHEN regexp_like(w.w_city, '^San') THEN 'West Coast'
            WHEN regexp_like(w.w_city, 'County$') THEN 'County City'
            ELSE 'Other'
        END AS city_category,
        regexp_extract(w.w_warehouse_name, '^([^ ]+)', 1) AS warehouse_prefix,
        w.w_city || ' - ' || w.w_street_type AS city_street_combo
    FROM sold s
    JOIN date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON s.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city || ' - ' || w.w_street_type LIKE '%Ave'
),
avg_profit_per_mode AS (
    SELECT
        sm.sm_type,
        avg(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ext_sales_price > 1000
    GROUP BY sm.sm_type
),
final AS (
    SELECT
        j.d_year,
        j.sm_type,
        j.w_warehouse_name,
        j.city_category,
        SUM(j.ws_net_profit) AS total_profit,
        COUNT(*) AS orders_cnt,
        CASE
            WHEN SUM(j.ws_net_profit) > 50000 THEN 'High'
            WHEN SUM(j.ws_net_profit) > 20000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_tier,
        ap.avg_profit,
        RANK() OVER (PARTITION BY j.d_year ORDER BY SUM(j.ws_net_profit) DESC) AS profit_rank
    FROM joined j
    LEFT JOIN avg_profit_per_mode ap ON j.sm_type = ap.sm_type
    GROUP BY
        j.d_year,
        j.sm_type,
        j.w_warehouse_name,
        j.city_category,
        ap.avg_profit
)
SELECT
    d_year,
    sm_type,
    w_warehouse_name,
    city_category,
    total_profit,
    orders_cnt,
    profit_tier,
    avg_profit,
    profit_rank,
    (SELECT avg(ws_net_profit) FROM web_sales) AS overall_avg_profit
FROM final
WHERE city_category = 'Other'
  AND w_warehouse_name LIKE '%Warehouse%'
ORDER BY profit_rank, total_profit DESC
LIMIT 100
