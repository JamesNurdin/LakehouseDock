SELECT
    p.p_promo_sk,
    i.i_item_id,
    i.i_product_name,
    SUM(ss.ss_ext_sales_price) AS promo_sales,
    SUM(ss.ss_ext_sales_price * ss.ss_quantity) AS weighted_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discounts,
    SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END) AS returns_amount,
    (SUM(ss.ss_ext_sales_price) - SUM(CASE WHEN wr.wr_return_quantity IS NOT NULL THEN wr.wr_return_amt_inc_tax ELSE 0 END)) / NULLIF(SUM(ss.ss_ext_sales_price),0) AS sales_to_return_ratio,
    MAX(ss.ss_sold_date_sk) AS last_sale_date_sk,
    DENSE_RANK() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_dense_rank
FROM promotion p
JOIN item i ON i.i_item_sk = p.p_item_sk
LEFT JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
WHERE p.p_discount_active = 'N' AND p.p_cost > 0
GROUP BY p.p_promo_sk, i.i_item_id, i.i_product_name, p.p_cost
HAVING SUM(ss.ss_ext_sales_price) BETWEEN 5000 AND 20000
ORDER BY sales_dense_rank ASC
