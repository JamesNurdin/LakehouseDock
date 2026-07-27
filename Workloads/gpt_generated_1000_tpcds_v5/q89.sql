WITH warehouse_inventory AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    w.w_state,
    cd_cs.cd_gender,
    t.t_hour,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    sr.sr_ticket_number,
    sr.sr_return_quantity,
    p_cs.p_promo_name,
    CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    wi.total_qty_on_hand,
    (SELECT AVG(total_qty_on_hand) FROM warehouse_inventory) AS avg_warehouse_qty,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY (cs.cs_ext_sales_price + ws.ws_ext_sales_price) DESC) AS sales_rank
FROM catalog_sales cs
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd_cs
    ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN warehouse_inventory wi
    ON w.w_warehouse_sk = wi.inv_warehouse_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = t.t_time_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN customer_demographics cd_ws
    ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
WHERE
    cs.cs_quantity > 5
    AND ws.ws_quantity > 2
    AND sr.sr_return_quantity > 0
    AND p_cs.p_discount_active = 'Y'
    AND w.w_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND cd_cs.cd_gender = 'F'
ORDER BY
    sales_rank,
    w.w_warehouse_name,
    cs.cs_order_number
LIMIT 100
