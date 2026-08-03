WITH email_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_email = 'Y'
),

tv_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
),

target_customers AS (
    SELECT customer_sk
    FROM email_customers
    EXCEPT
    SELECT customer_sk
    FROM tv_customers
)
SELECT
    w.w_warehouse_name,
    sm.sm_carrier,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    SUM(p.price) AS total_price_elements
FROM catalog_sales cs
JOIN target_customers tc ON cs.cs_bill_customer_sk = tc.customer_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN LATERAL (
    SELECT ARRAY[cs.cs_wholesale_cost, cs.cs_list_price] AS price_arr
) l ON true
CROSS JOIN UNNEST(l.price_arr) AS p(price)
GROUP BY w.w_warehouse_name, sm.sm_carrier
HAVING AVG(cs.cs_net_profit) > 100
ORDER BY avg_net_profit DESC, w.w_warehouse_name
