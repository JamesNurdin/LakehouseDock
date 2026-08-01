WITH sampled_sales AS (
    SELECT
        ws_sold_time_sk,
        ws_item_sk,
        ws_warehouse_sk,
        ws_web_site_sk,
        ws_promo_sk,
        ws_order_number,
        ws_ext_sales_price,
        ws_ext_ship_cost,
        ws_wholesale_cost,
        ws_list_price,
        ws_net_paid_inc_ship_tax
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    ws_site.web_name,
    td.t_sub_shift,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ws.ws_wholesale_cost) AS min_wholesale_cost,
    MAX(ws.ws_list_price) AS max_list_price,
    (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
FROM sampled_sales ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
WHERE
    td.t_minute IN (5, 10)
    AND td.t_sub_shift = 'morning'
    AND w.w_gmt_offset = -6.00
    AND i.i_current_price BETWEEN 50 AND 200
    AND ws.ws_net_paid_inc_ship_tax > 1000
    AND p.p_discount_active = 'Y'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    ws_site.web_name,
    td.t_sub_shift
ORDER BY total_sales DESC
LIMIT 100
