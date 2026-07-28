WITH sales_promo AS (
    SELECT
        d.d_year,
        REGEXP_EXTRACT(p.p_promo_id, 'A+([A-Z]+)', 1) AS promo_suffix,
        ss.ss_net_paid,
        s.s_store_sk,
        s.s_store_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE REGEXP_LIKE(p.p_promo_id, '^A{5,}')
      AND s.s_store_name LIKE '%Super%'
      AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    d_year,
    promo_suffix,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_net_paid) AS avg_net_paid,
    COUNT(DISTINCT s_store_sk) AS store_count
FROM sales_promo
GROUP BY d_year, promo_suffix
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
