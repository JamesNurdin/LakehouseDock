WITH sampled_sales AS (
    SELECT
        ws_order_number,
        ws_net_profit,
        ws_ext_ship_cost,
        ws_warehouse_sk,
        ws_promo_sk,
        ws_bill_addr_sk,
        ws_ship_addr_sk
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),
intersected_orders AS (
    SELECT ws_order_number FROM (
        SELECT ss.ws_order_number
        FROM sampled_sales ss
        JOIN customer_address ca_bill
          ON ss.ws_bill_addr_sk = ca_bill.ca_address_sk
        WHERE regexp_like(ca_bill.ca_suite_number, '^Suite [0-9]+$')
          AND ca_bill.ca_state LIKE 'A%'
    )
    INTERSECT
    SELECT ws_order_number FROM (
        SELECT ss.ws_order_number
        FROM sampled_sales ss
        JOIN customer_address ca_ship
          ON ss.ws_ship_addr_sk = ca_ship.ca_address_sk
        WHERE regexp_like(ca_ship.ca_suite_number, '^Suite [A-Z]$')
          AND ca_ship.ca_state LIKE 'C%'
    )
)
SELECT
    w.w_state,
    p.p_channel_email,
    CONCAT('Warehouse ', w.w_warehouse_id) AS warehouse_label,
    SUM(s.ws_net_profit) AS total_profit,
    SUM(s.ws_ext_ship_cost) AS total_ship_cost
FROM sampled_sales s
JOIN intersected_orders io
  ON s.ws_order_number = io.ws_order_number
JOIN warehouse w
  ON s.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
  ON s.ws_promo_sk = p.p_promo_sk
WHERE regexp_extract(w.w_warehouse_id, '(A{3,})', 1) IS NOT NULL
  AND w.w_city LIKE '%ville%'
GROUP BY ROLLUP (w.w_state, p.p_channel_email, w.w_warehouse_id)
ORDER BY total_profit DESC
LIMIT 100
