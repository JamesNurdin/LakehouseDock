SELECT
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    CONCAT(p.p_promo_id, '-', p.p_promo_name) AS promo_label,
    SUBSTR(p.p_promo_name, 1, 5) AS promo_name_prefix,
    CAST(regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS INTEGER) AS discount_pct,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_discount_amt) AS total_ext_discount,
    COUNT(*) AS transaction_cnt,
    'regex_filter' AS filter_source
FROM store_sales ss
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE regexp_like(p.p_promo_name, '(?i)discount')
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    CONCAT(p.p_promo_id, '-', p.p_promo_name),
    SUBSTR(p.p_promo_name, 1, 5),
    CAST(regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS INTEGER)

UNION

SELECT
    p.p_promo_id AS promo_id,
    p.p_promo_name AS promo_name,
    CONCAT(p.p_promo_id, '-', p.p_promo_name) AS promo_label,
    SUBSTR(p.p_promo_name, 1, 5) AS promo_name_prefix,
    CAST(regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS INTEGER) AS discount_pct,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_ext_discount_amt) AS total_ext_discount,
    COUNT(*) AS transaction_cnt,
    'email_channel' AS filter_source
FROM store_sales ss
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
WHERE p.p_channel_email LIKE '%promo@%'
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    CONCAT(p.p_promo_id, '-', p.p_promo_name),
    SUBSTR(p.p_promo_name, 1, 5),
    CAST(regexp_extract(p.p_promo_name, '(\\d+)%', 1) AS INTEGER)

ORDER BY total_net_paid DESC
LIMIT 100
