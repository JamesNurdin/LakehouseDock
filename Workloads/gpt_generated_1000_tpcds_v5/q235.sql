WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1203
      AND sm.sm_code IN ('AIR', 'SEA')
      AND p.p_discount_active = 'Y'
      AND cp.cp_type = 'catalog'
)
SELECT
    sm.sm_code,
    p.p_promo_name,
    cp.cp_department,
    COUNT(DISTINCT s.cs_order_number) AS orders,
    SUM(s.cs_net_paid) AS total_net_paid,
    SUM(s.cs_net_profit) AS total_net_profit,
    SUM(CASE
            WHEN (
                SELECT SUM(cr.cr_return_amount)
                FROM catalog_returns cr
                WHERE cr.cr_order_number = s.cs_order_number
            ) IS NOT NULL THEN (
                SELECT SUM(cr.cr_return_amount)
                FROM catalog_returns cr
                WHERE cr.cr_order_number = s.cs_order_number
            )
            ELSE 0
        END) AS total_return_amount,
    AVG(s.cs_quantity) AS avg_quantity_per_order
FROM sales s
JOIN ship_mode sm ON s.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_order_number = s.cs_order_number
      AND cr.cr_return_amount > 0
)
GROUP BY
    sm.sm_code,
    p.p_promo_name,
    cp.cp_department
ORDER BY total_net_profit DESC
LIMIT 100
