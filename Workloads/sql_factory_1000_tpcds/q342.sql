SELECT
    p.p_promo_sk,
    p.p_promo_name,
    i.i_item_id,
    i.i_product_name,
    SUM(ss.ss_ext_sales_price) AS promo_sales_revenue,
    COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_return_amount,
    p.p_cost AS promo_cost,
    CASE
        WHEN p.p_cost = 0 THEN NULL
        ELSE (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) - p.p_cost) / p.p_cost
    END AS adjusted_roi,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS discount_status,
    RANK() OVER (ORDER BY CASE WHEN p.p_cost = 0 THEN 0 ELSE (SUM(ss.ss_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) - p.p_cost) / p.p_cost END DESC) AS roi_rank
FROM promotion p
JOIN item i ON i.i_item_sk = p.p_item_sk
LEFT JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
GROUP BY p.p_promo_sk, p.p_promo_name, i.i_item_id, i.i_product_name, p.p_cost, p.p_discount_active
HAVING SUM(ss.ss_ext_sales_price) > 0
ORDER BY roi_rank
LIMIT 10
