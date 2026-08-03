WITH sales_by_store AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        ss.ss_promo_sk AS promo_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(s.s_store_name, '^.*Mart.*$')
      AND s.s_state LIKE 'C%'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_city, ss.ss_promo_sk
    HAVING SUM(ss.ss_net_profit) > 1000
),
promo_info AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\w+)') AS first_word,
        p.p_channel_email,
        CASE WHEN p.p_discount_active = 'Y' THEN true ELSE false END AS discount_active
    FROM promotion p
    WHERE p.p_promo_name IS NOT NULL
)
SELECT
    ROW_NUMBER() OVER (ORDER BY COALESCE(s.total_net_profit, 0) DESC) AS row_num,
    COALESCE(s.s_store_name, 'NO_STORE') AS store_name,
    COALESCE(s.s_city, 'NO_CITY') AS city,
    p.p_promo_name,
    p.first_word,
    SUBSTRING(p.p_promo_name FROM 1 FOR 5) AS promo_prefix,
    CONCAT(COALESCE(s.s_store_name, ''), ' - ', COALESCE(p.p_promo_name, '')) AS store_promo_combined,
    s.total_net_paid,
    s.total_net_profit,
    p.discount_active,
    l.promo_name_len
FROM sales_by_store s
FULL OUTER JOIN promo_info p
    ON s.promo_sk = p.p_promo_sk
LEFT JOIN LATERAL (
    SELECT length(p.p_promo_name) AS promo_name_len
) l ON true
ORDER BY row_num
LIMIT 100
