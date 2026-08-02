WITH sales_promo AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_net_profit,
        d.d_year,
        s.s_state,
        s.s_city,
        s.s_zip,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        p.p_promo_name
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND regexp_like(s.s_city, '^[A-M].*')
      AND p.p_promo_name LIKE '%Discount%'
)
SELECT
    s_state,
    promo_word,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss_ticket_number) AS orders,
    MIN(CONCAT(s_city, ', ', s_state)) AS location,
    SUBSTRING(MIN(s_zip), 1, 5) AS zip_prefix,
    regexp_extract(promo_word, '^([A-Za-z]{2})', 1) AS promo_word_prefix
FROM sales_promo
CROSS JOIN UNNEST(split(p_promo_name, ' ')) AS t(promo_word)
GROUP BY GROUPING SETS (
    (s_state, promo_word),
    (s_state),
    (promo_word)
)
HAVING SUM(ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
