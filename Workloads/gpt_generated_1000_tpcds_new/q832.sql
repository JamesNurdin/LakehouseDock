WITH sampled_store AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    p.p_promo_name,
    sm.sm_carrier,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT ws.ws_order_number)   AS distinct_web_orders,
    SUM(ss.ss_net_paid)                  AS total_store_net_paid,
    AVG(ws.ws_sales_price)               AS avg_web_sales_price,
    MIN(ss.ss_coupon_amt)                AS min_store_coupon_amt,
    MAX(ws.ws_ext_ship_cost)             AS max_web_ship_cost
FROM sampled_store ss
RIGHT OUTER JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
FULL OUTER JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
RIGHT OUTER JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE p.p_end_date_sk BETWEEN 2450200 AND 2450400
  AND ss.ss_quantity > 1
  AND ws.ws_sales_price BETWEEN 10 AND 200
GROUP BY
    p.p_promo_name,
    sm.sm_carrier
ORDER BY total_store_net_paid DESC
LIMIT 100
