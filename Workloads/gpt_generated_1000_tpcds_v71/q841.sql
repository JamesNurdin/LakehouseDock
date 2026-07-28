WITH filtered_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        ss.ss_net_profit,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_digits
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '[0-9]{3,}')
      AND s.s_store_name LIKE 'A%'
)
SELECT
    CONCAT(fs.s_city, ', ', fs.s_state) AS location,
    SUBSTR(fs.s_store_name, 1, 3) AS store_prefix,
    fs.d_year,
    fs.d_month_seq,
    SUM(fs.ss_net_profit) AS total_net_profit,
    LISTAGG(DISTINCT fs.promo_digits, ',') WITHIN GROUP (ORDER BY fs.promo_digits) AS promo_digits_list
FROM filtered_sales fs
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    WHERE sr.sr_store_sk = fs.s_store_sk
      AND dr.d_year = fs.d_year
      AND dr.d_month_seq = fs.d_month_seq
)
GROUP BY
    fs.s_city,
    fs.s_state,
    fs.s_store_name,
    fs.d_year,
    fs.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
