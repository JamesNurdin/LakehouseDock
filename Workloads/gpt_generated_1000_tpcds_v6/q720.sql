WITH promo_year_sales AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND c.c_birth_country IN ('JAPAN', 'SWITZERLAND')
      AND ss.ss_ext_sales_price > 1000
      AND p.p_discount_active = 'Y'
      AND d.d_current_year = 'Y'
    GROUP BY p.p_promo_id, d.d_year
)
SELECT
    pys.p_promo_id,
    pys.d_year,
    pys.total_sales,
    pys.total_profit,
    pys.sales_cnt,
    (
        SELECT AVG(ss2.ss_ext_discount_amt)
        FROM store_sales ss2
        JOIN promotion p2 ON ss2.ss_promo_sk = p2.p_promo_sk
        WHERE p2.p_promo_id = pys.p_promo_id
    ) AS avg_discount_amt
FROM promo_year_sales pys
WHERE NOT EXISTS (
    SELECT 1
    FROM store_sales ss3
    JOIN promotion p3 ON ss3.ss_promo_sk = p3.p_promo_sk
    WHERE p3.p_promo_id = pys.p_promo_id
      AND ss3.ss_net_profit < 0
)
ORDER BY pys.total_sales DESC
LIMIT 100
