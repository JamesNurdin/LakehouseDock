WITH recent_sales AS (
    SELECT ss.*, d.d_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    s.s_store_id,
    MAX(s.s_store_name) AS store_name,
    i.i_category,
    MIN(SUBSTRING(i.i_item_desc FROM 1 FOR 10)) AS short_desc,
    SUM(recent_sales.ss_ext_sales_price) AS total_sales,
    SUM(recent_sales.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_transactions,
    SUM(CASE WHEN EXISTS (SELECT 1 FROM promotion p WHERE p.p_promo_sk = recent_sales.ss_promo_sk) THEN 1 ELSE 0 END) AS promo_transactions,
    CASE WHEN regexp_like(MAX(s.s_store_name), 'Market') THEN 1 ELSE 0 END AS is_market_store
FROM recent_sales
JOIN store s ON recent_sales.ss_store_sk = s.s_store_sk
JOIN item i ON recent_sales.ss_item_sk = i.i_item_sk
WHERE regexp_like(i.i_item_desc, '\\d{3}')
  AND s.s_store_name LIKE '%Store%'
GROUP BY ROLLUP (s.s_store_id, i.i_category)
ORDER BY s.s_store_id, i.i_category
LIMIT 100
