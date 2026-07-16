SELECT
    s.s_store_id,
    d_sale.d_year,
    d_sale.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    SUM(COALESCE(wp_agg.pages_created, 0)) AS total_pages_created,
    ROW_NUMBER() OVER (
        PARTITION BY d_sale.d_year, d_sale.d_month_seq
        ORDER BY SUM(ss.ss_ext_sales_price) DESC
    ) AS sales_rank
FROM store_sales ss
JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN (
    SELECT wp_creation_date_sk, COUNT(DISTINCT wp_web_page_id) AS pages_created
    FROM web_page
    GROUP BY wp_creation_date_sk
) wp_agg ON wp_agg.wp_creation_date_sk = d_sale.d_date_sk
WHERE (s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > d_sale.d_date_sk)
  AND d_sale.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
GROUP BY s.s_store_id, d_sale.d_year, d_sale.d_month_seq
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY d_sale.d_year, d_sale.d_month_seq, total_sales DESC
LIMIT 100
