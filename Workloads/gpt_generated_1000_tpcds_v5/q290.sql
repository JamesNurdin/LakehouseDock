WITH ws_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        p.p_promo_id,
        p.p_discount_active,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory_qty
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
      AND ca.ca_city = 'Seattle'
      AND hd.hd_income_band_sk BETWEEN 5 AND 10
      AND p.p_discount_active = 'Y'
      AND ws.ws_sold_date_sk BETWEEN 2450815 AND 2451067
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name, w.w_state, p.p_promo_id, p.p_discount_active
)
SELECT
    w_warehouse_name,
    w_state,
    AVG(total_profit) AS avg_profit_per_promo,
    SUM(total_quantity) AS sum_quantity_sold,
    SUM(total_inventory_qty) AS sum_inventory_qty,
    AVG(total_profit) / NULLIF(SUM(total_quantity), 0) AS avg_profit_per_unit
FROM ws_agg
WHERE total_profit > 10000
GROUP BY w_warehouse_name, w_state
HAVING SUM(total_quantity) > 1000
ORDER BY avg_profit_per_promo DESC
LIMIT 100
