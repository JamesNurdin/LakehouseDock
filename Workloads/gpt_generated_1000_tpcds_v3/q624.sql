WITH store_sales_agg AS (
    SELECT ss_item_sk,
           SUM(ss_ext_sales_price) AS store_total_sales,
           SUM(ss_quantity) AS store_total_quantity
    FROM store_sales
    GROUP BY ss_item_sk
),
inventory_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    t.t_hour,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    ca.ca_city,
    wp.wp_url,
    w.w_warehouse_name,
    p.p_promo_name,
    ws.ws_net_paid_inc_tax,
    COALESCE(sr.store_total_sales, 0) AS store_total_sales,
    COALESCE(inv_agg.total_on_hand, 0) AS inventory_on_hand,
    CASE WHEN wr.wr_return_quantity IS NOT NULL THEN 'Returned' ELSE 'No Return' END AS return_status,
    CASE
        WHEN ws.ws_net_paid_inc_tax > 1000 THEN 'High'
        WHEN ws.ws_net_paid_inc_tax BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS payment_category,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY ws.ws_net_paid_inc_tax DESC) AS promo_rank,
    DENSE_RANK() OVER (ORDER BY ws.ws_net_paid_inc_tax DESC) AS overall_rank,
    COUNT(DISTINCT i.i_item_id) OVER (PARTITION BY w.w_warehouse_name) AS distinct_items_in_warehouse,
    (SELECT COUNT(DISTINCT ss_customer_sk) FROM store_sales ss WHERE ss.ss_item_sk = ws.ws_item_sk) AS distinct_store_customers
FROM web_sales ws
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN store_sales_agg sr
    ON i.i_item_sk = sr.ss_item_sk
LEFT JOIN inventory_agg inv_agg
    ON i.i_item_sk = inv_agg.inv_item_sk
    AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND w.w_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND ws.ws_net_paid_inc_tax > 500
ORDER BY ws.ws_net_paid_inc_tax DESC
LIMIT 100
