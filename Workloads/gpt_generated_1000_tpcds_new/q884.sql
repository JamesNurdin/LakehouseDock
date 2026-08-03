WITH sampled_store_sales AS (
    SELECT DISTINCT ss_customer_sk, ss_sold_date_sk, ss_quantity, ss_net_paid, ss_promo_sk
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 2
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cc.cc_name,
    sm.sm_carrier,
    w.w_warehouse_name,
    p.p_promo_name,
    cs.cs_net_paid,
    ws.ws_net_paid,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY cs.cs_net_paid DESC) AS promo_sales_rank,
    COUNT(DISTINCT cs.cs_order_number) OVER (PARTITION BY c.c_customer_sk) AS distinct_orders_per_customer
FROM
    customer c
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    LEFT JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    FULL OUTER JOIN promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
    LEFT JOIN sampled_store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE
    c.c_salutation = 'Mr.'
    AND c.c_birth_year BETWEEN 1950 AND 1960
    AND cc.cc_state = 'CA'
    AND sm.sm_carrier IN ('FEDEX', 'USPS')
    AND w.w_country = 'United States'
    AND p.p_discount_active = 'Y'
    AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451180
    AND EXISTS (
        SELECT 1
        FROM (
            SELECT DISTINCT p2.p_promo_sk
            FROM promotion p2
            WHERE p2.p_discount_active = 'Y'
        ) d
        WHERE d.p_promo_sk = p.p_promo_sk
    )
ORDER BY
    cs.cs_net_paid DESC
LIMIT 100
