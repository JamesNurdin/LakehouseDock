WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\d{4})', 1) AS promo_code,
        concat('Code-', regexp_extract(p.p_promo_name, '(\\d{4})', 1)) AS full_code
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    WHERE d_start.d_year = 2002
      AND regexp_like(p.p_promo_name, '^PROMO-[0-9]{4}$')
      AND p.p_channel_details LIKE '%national%'
)
SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    pf.full_code,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit
FROM promo_filtered pf
JOIN store_sales ss ON ss.ss_promo_sk = pf.p_promo_sk
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
GROUP BY d_sales.d_year, d_sales.d_month_seq, pf.full_code
ORDER BY total_profit DESC
LIMIT 100
