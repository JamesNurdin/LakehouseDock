SELECT
    p.p_promo_name,
    i.i_brand,
    i.i_class,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_sales_price) / NULLIF(COUNT(DISTINCT ss.ss_customer_sk),0) AS avg_spend_per_customer,
    SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_amt_inc_tax ELSE 0 END) AS total_returns,
    (SUM(ss.ss_ext_sales_price) - SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_amt_inc_tax ELSE 0 END)) / NULLIF(SUM(ss.ss_ext_sales_price),0) AS net_sales_ratio,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS brand_sales_rank
FROM promotion p
JOIN item i ON i.i_item_sk = p.p_item_sk
LEFT JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_color = 'RED' AND p.p_promo_name LIKE '%Summer%'
GROUP BY p.p_promo_name, i.i_brand, i.i_class
ORDER BY net_sales_ratio DESC
LIMIT 8
