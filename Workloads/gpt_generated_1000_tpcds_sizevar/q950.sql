WITH
    filtered_sales AS (
        SELECT *
        FROM catalog_sales
        WHERE cs_ext_list_price > 5000
          AND cs_quantity BETWEEN 1 AND 10
          AND cs_ship_addr_sk IN (3319971, 1650438)
          AND cs_wholesale_cost < 3000
          AND cs_net_paid_inc_tax > 1000
          AND cs_net_profit IS NOT NULL
    ),
    order_intersection AS (
        SELECT cs_order_number
        FROM filtered_sales
        WHERE cs_ext_discount_amt > 0
        INTERSECT
        SELECT cs_order_number
        FROM filtered_sales
        WHERE cs_ext_ship_cost > 0
    )
SELECT
    w.w_warehouse_name,
    td.t_meal_time,
    COUNT(DISTINCT fs.cs_item_sk) AS distinct_items_sold,
    SUM(fs.cs_net_profit) AS total_profit,
    AVG(fs.cs_quantity) AS avg_quantity,
    MIN(fs.cs_ext_list_price) AS min_list_price,
    MAX(fs.cs_ext_list_price) AS max_list_price,
    CASE
        WHEN SUM(fs.cs_net_profit) > 100000 THEN 'HIGH'
        WHEN SUM(fs.cs_net_profit) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    oi_l.order_cnt
FROM filtered_sales fs
RIGHT JOIN warehouse w
    ON fs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td
    ON fs.cs_sold_time_sk = td.t_time_sk
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS order_cnt
    FROM order_intersection oi
    WHERE oi.cs_order_number = fs.cs_order_number
) oi_l ON true
WHERE w.w_suite_number = 'Suite 350'
  AND w.w_zip = '74136'
  AND td.t_meal_time = 'dinner'
  AND td.t_second IN (5, 12, 17)
  AND fs.cs_ext_list_price BETWEEN 4000 AND 10000
  AND fs.cs_quantity >= 2
GROUP BY w.w_warehouse_name, td.t_meal_time, oi_l.order_cnt
ORDER BY total_profit DESC
LIMIT 100
