WITH items_pat AS (
    SELECT
        i_item_sk,
        i_item_desc,
        regexp_extract(i_item_desc, '(\\d{4})') AS four_digit_code,
        substring(i_item_desc, 1, 10) AS short_desc
    FROM
        item
    WHERE
        regexp_like(i_item_desc, '(?i)premium')
        AND i_item_desc LIKE '%Deluxe%'
)
SELECT
    s.s_store_name,
    d.d_year,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items_sold,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    MIN(items_pat.four_digit_code) AS sample_code,
    MAX(items_pat.short_desc) AS example_desc
FROM
    store_sales ss
JOIN
    date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
JOIN
    store s
        ON ss.ss_store_sk = s.s_store_sk
JOIN
    promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
JOIN
    items_pat
        ON ss.ss_item_sk = items_pat.i_item_sk
WHERE
    p.p_promo_name LIKE 'Summer%'
    AND s.s_city LIKE 'Washington%'
GROUP BY
    s.s_store_name,
    d.d_year,
    p.p_promo_name
ORDER BY
    total_net_paid DESC
LIMIT 100
