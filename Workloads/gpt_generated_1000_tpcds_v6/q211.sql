WITH filtered_sales AS (
    SELECT
        ss.ss_net_paid,
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        i.i_product_name,
        p.p_promo_name
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_product_name, '^[A-Za-z]+\\s+.*')
      AND p.p_promo_name LIKE '%Discount%'
      AND d.d_year = 2002
)
SELECT
    s_store_id,
    s_store_name,
    CONCAT(CAST(d_year AS varchar), '-', LPAD(CAST(d_month_seq AS varchar), 2, '0')) AS year_month,
    COUNT(*) AS sales_transactions,
    SUM(ss_net_paid) AS total_net_paid,
    REGEXP_EXTRACT(MIN(i_product_name), '[A-Za-z]+') AS first_word_product
FROM filtered_sales
GROUP BY s_store_id, s_store_name, d_year, d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
