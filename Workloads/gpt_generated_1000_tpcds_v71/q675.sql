WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND c.c_email_address LIKE '%@%.com'
      AND t.t_shift = 'first'
)
SELECT
    p.p_promo_name,
    sm.sm_type,
    CONCAT(p.p_promo_name, ' - ', sm.sm_type) AS promo_ship_mode,
    SUM(fs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_count,
    AVG(fs.cs_quantity) AS avg_quantity
FROM filtered_sales fs
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
    p.p_promo_name,
    sm.sm_type,
    CONCAT(p.p_promo_name, ' - ', sm.sm_type)
ORDER BY total_profit DESC
LIMIT 100
