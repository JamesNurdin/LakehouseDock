WITH sales_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        w.w_state,
        ws.ws_promo_sk,
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS sales_count
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458840 AND 2459205
      AND p.p_discount_active = 'Y'
      AND c.c_birth_year > 1960
    GROUP BY ws.ws_warehouse_sk, w.w_state, ws.ws_promo_sk, p.p_promo_name
),
inventory_agg AS (
    SELECT
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM inventory i
    GROUP BY i.inv_warehouse_sk
)
SELECT
    s.w_state,
    s.p_promo_name,
    s.total_net_profit,
    s.total_quantity,
    s.sales_count,
    s.total_net_profit / NULLIF(s.sales_count, 0) AS avg_net_profit_per_sale,
    i.total_inventory_on_hand
FROM sales_agg s
JOIN inventory_agg i ON s.ws_warehouse_sk = i.inv_warehouse_sk
WHERE i.total_inventory_on_hand > 5000
ORDER BY avg_net_profit_per_sale DESC
LIMIT 10
