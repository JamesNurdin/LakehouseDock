WITH order_intersect AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 1500
    INTERSECT
    SELECT wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_amt > 200
)
SELECT
    w.w_warehouse_name,
    td.t_sub_shift,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_tax) AS avg_tax,
    MIN(cs.cs_net_profit) AS min_profit,
    MAX(i.inv_quantity_on_hand) AS max_inventory,
    LAG(SUM(cs.cs_ext_sales_price)) OVER (PARTITION BY w.w_warehouse_id ORDER BY w.w_warehouse_name) AS lag_total_sales,
    item_max.max_price_for_item
FROM catalog_sales cs
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
JOIN order_intersect oi
    ON cs.cs_order_number = oi.cs_order_number
CROSS JOIN LATERAL (
    SELECT MAX(cs2.cs_ext_sales_price) AS max_price_for_item
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = cs.cs_item_sk
) AS item_max
WHERE
    td.t_sub_shift = 'morning'
    AND td.t_time BETWEEN 2 AND 11
    AND w.w_state = 'CA'
    AND i.inv_quantity_on_hand > 200
    AND cs.cs_ext_tax > 20.00
GROUP BY
    w.w_warehouse_name,
    td.t_sub_shift,
    w.w_warehouse_id,
    cs.cs_item_sk,
    item_max.max_price_for_item
ORDER BY total_sales DESC
LIMIT 100
