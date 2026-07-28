WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_net_paid,
        ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND regexp_like(p.p_promo_name, '(?i)summer')
)
SELECT
    s.s_state,
    p.p_promo_name,
    concat(s.s_state, '-', p.p_promo_name) AS state_promo,
    max(substring(s.s_city, 1, 5)) AS city_prefix,
    sum(fs.ss_net_paid) AS total_net_paid,
    sum(fs.ss_net_profit) AS total_profit,
    count(*) AS sales_cnt
FROM filtered_sales fs
JOIN store s
    ON fs.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON fs.ss_promo_sk = p.p_promo_sk
WHERE s.s_city LIKE 'New%'
GROUP BY ROLLUP(s.s_state, p.p_promo_name)
ORDER BY s.s_state, p.p_promo_name
LIMIT 100
