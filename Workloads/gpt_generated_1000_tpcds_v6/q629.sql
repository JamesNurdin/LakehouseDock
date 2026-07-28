WITH active_ids AS (
        SELECT p_promo_sk AS id
        FROM promotion
        WHERE p_discount_active = 'Y'
        UNION
        SELECT cc_call_center_sk AS id
        FROM call_center
        WHERE cc_closed_date_sk IS NULL
    ),
    avg_ws_net_paid AS (
        SELECT AVG(ws_net_paid) AS avg_val
        FROM web_sales
        WHERE ws_ship_date_sk BETWEEN 2450860 AND 2450900
    )
SELECT
    cust_bill.c_customer_id,
    cc.cc_state,
    SUM(cs.cs_net_profit + ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
        ELSE 'LOW'
    END AS profit_category,
    (SELECT avg_val FROM avg_ws_net_paid) AS avg_ws_net_paid,
    COUNT(DISTINCT CASE WHEN cs.cs_promo_sk IN (SELECT id FROM active_ids) THEN cs.cs_order_number END) AS orders_with_active_id
FROM catalog_sales cs
JOIN customer cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
JOIN web_page wp1
    ON ws.ws_web_page_sk = wp1.wp_web_page_sk
JOIN web_page wp2
    ON wp2.wp_customer_sk = cust_ship.c_customer_sk
WHERE cc.cc_state IN ('CA', 'TX', 'NY')
  AND cs.cs_ext_tax > 10
GROUP BY cust_bill.c_customer_id, cc.cc_state
HAVING SUM(cs.cs_net_profit + ws.ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
