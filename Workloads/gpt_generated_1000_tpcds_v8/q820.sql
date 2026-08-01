WITH
sampled_sales AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),
promo_ship AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_quantity,
        p.p_promo_name,
        sm.sm_code,
        CASE
            WHEN p.p_discount_active = 'Y' THEN 'Active'
            ELSE 'Inactive'
        END AS promo_status
    FROM sampled_sales ws
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
full_promo_ship AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        p.p_promo_name,
        sm.sm_code
    FROM web_sales ws
    FULL OUTER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
intersect_keys AS (
    SELECT ws_order_number FROM web_sales WHERE ws_quantity > 10
    INTERSECT
    SELECT ws_order_number FROM web_sales WHERE ws_net_paid > 1000
),
sales_with_lateral AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_discount_amt,
        l.discount_category
    FROM web_sales ws
    LEFT JOIN LATERAL (
        SELECT
            CASE
                WHEN ws.ws_ext_discount_amt > 100 THEN 'High'
                WHEN ws.ws_ext_discount_amt > 0 THEN 'Low'
                ELSE 'None'
            END AS discount_category
    ) l ON true
),
cross_join_set AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        t.multiplier,
        ws.ws_net_paid * t.multiplier AS scaled_payment
    FROM web_sales ws
    CROSS JOIN (VALUES (1), (2), (3)) AS t(multiplier)
    WHERE ws.ws_order_number % 10 = 0
)

SELECT
    ps.promo_status,
    COUNT(DISTINCT ps.ws_order_number) AS orders,
    SUM(ps.ws_net_paid) AS total_paid,
    AVG(ps.ws_quantity) AS avg_quantity,
    (SELECT COUNT(*) FROM full_promo_ship WHERE p_promo_name IS NULL) AS unmatched_promo_count
FROM promo_ship ps
WHERE EXISTS (
    SELECT 1
    FROM sales_with_lateral swl
    WHERE swl.ws_order_number = ps.ws_order_number
      AND swl.discount_category = 'High'
)
GROUP BY ps.promo_status

UNION ALL

SELECT
    CASE WHEN c.multiplier = 1 THEN 'Base' ELSE 'Scaled' END AS promo_status,
    COUNT(DISTINCT c.ws_order_number) AS orders,
    SUM(c.scaled_payment) AS total_paid,
    AVG(c.scaled_payment) AS avg_quantity,
    (SELECT COUNT(*) FROM full_promo_ship WHERE p_promo_name IS NULL) AS unmatched_promo_count
FROM cross_join_set c
WHERE c.ws_order_number IN (SELECT ws_order_number FROM intersect_keys)
GROUP BY CASE WHEN c.multiplier = 1 THEN 'Base' ELSE 'Scaled' END

ORDER BY total_paid DESC
LIMIT 100
