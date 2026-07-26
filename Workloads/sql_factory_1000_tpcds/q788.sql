SELECT
    p.p_promo_sk,
    p.p_promo_name,
    i.i_category,
    i.i_brand,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_transactions,
    AVG(ss.ss_ext_sales_price) AS avg_ticket_price,
    SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END) AS total_returns,
    p.p_cost,
    CASE WHEN p.p_cost = 0 THEN NULL ELSE (SUM(ss.ss_ext_sales_price) - SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END) - p.p_cost) / p.p_cost END AS roi,
    ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS category_rank
FROM promotion p
JOIN item i ON i.i_item_sk = p.p_item_sk
LEFT JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
WHERE p.p_discount_active = 'Y'
GROUP BY p.p_promo_sk, p.p_promo_name, i.i_category, i.i_brand, p.p_cost
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY roi DESC
LIMIT 5
