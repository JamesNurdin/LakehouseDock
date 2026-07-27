WITH promo_sales AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        d.d_year,
        d.d_month_seq,
        concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_month_seq AS varchar), 2, '0')) AS year_month,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ss.ss_net_profit) >= 0 THEN 'Positive' ELSE 'Negative' END AS profit_sign,
        regexp_extract(p.p_promo_name, '([A-Za-z]{3})', 1) AS promo_prefix,
        substring(p.p_promo_name, 1, 5) AS promo_start5
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(p.p_promo_name, '^a')
      AND p.p_purpose = 'Unknown'
      AND s.s_store_name LIKE '%Market%'
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        d.d_year,
        d.d_month_seq,
        concat(cast(d.d_year AS varchar), '-', lpad(cast(d.d_month_seq AS varchar), 2, '0')),
        regexp_extract(p.p_promo_name, '([A-Za-z]{3})', 1),
        substring(p.p_promo_name, 1, 5)
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    promo_id,
    promo_name,
    year_month,
    total_net_profit,
    sales_cnt,
    profit_sign,
    promo_prefix,
    promo_start5,
    concat('Promo ', promo_name) AS promo_label,
    total_net_profit / (SELECT AVG(ss_net_profit) FROM store_sales) AS profit_vs_overall_avg
FROM promo_sales
WHERE total_net_profit > (SELECT AVG(total_net_profit) FROM promo_sales)
ORDER BY total_net_profit DESC
LIMIT 100
