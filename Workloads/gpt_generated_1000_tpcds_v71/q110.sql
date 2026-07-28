WITH sales_enriched AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_promo_sk,
        p.p_promo_name,
        ss.ss_net_paid,
        ss.ss_net_profit,
        CASE
            WHEN ss.ss_net_profit > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_flag,
        regexp_extract(p.p_promo_name, '(\\d{4})', 1) AS promo_year_code,
        CONCAT(s.s_store_name, ' - ', p.p_promo_name) AS store_promo_desc
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_store_name LIKE '%Market%'
      AND regexp_like(p.p_promo_name, '^Summer.*')
)
SELECT
    se.d_year,
    se.s_store_name,
    COUNT(*) AS sales_cnt,
    SUM(se.ss_net_paid) AS total_net_paid,
    SUM(se.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT se.promo_year_code) AS distinct_promo_year_codes,
    SUM(CASE WHEN se.profit_flag = 'Profit' THEN se.ss_net_paid ELSE 0 END) AS profit_sales,
    SUM(CASE WHEN se.profit_flag = 'Loss' THEN se.ss_net_paid ELSE 0 END) AS loss_sales
FROM sales_enriched se
GROUP BY se.d_year, se.s_store_name
ORDER BY total_net_paid DESC
LIMIT 100
