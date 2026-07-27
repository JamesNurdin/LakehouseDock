WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\w{3})', 1) AS promo_prefix,
        p.p_channel_dmail,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales,
        COUNT(*) AS sales_cnt
    FROM promotion p
    JOIN store_sales ss
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
        regexp_like(p.p_promo_name, 'tion$')               -- name ends with "tion"
        AND p.p_channel_dmail = 'Y'                         -- dmail channel active
        AND ss.ss_ext_sales_price > 5000                    -- high‑value sales only
    GROUP BY
        p.p_promo_sk,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\w{3})', 1),
        p.p_channel_dmail
)
SELECT
    ps.p_promo_name,
    ps.promo_prefix,
    CONCAT(ps.p_promo_name, '_', ps.p_channel_dmail) AS promo_label,
    ps.total_net_paid,
    ps.total_ext_sales,
    ps.sales_cnt
FROM promo_sales ps
WHERE ps.promo_prefix LIKE 'e%'
ORDER BY ps.total_net_paid DESC
LIMIT 100
