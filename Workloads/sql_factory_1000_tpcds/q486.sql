SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_size,
    SUM(ss.ss_ext_sales_price) AS sales_revenue,
    SUM(ss.ss_ext_discount_amt) AS discount_total,
    SUM(ss.ss_net_profit) AS profit_total,
    COUNT(DISTINCT ss.ss_ticket_number) AS txn_count,
    MAX(CASE WHEN p.p_discount_active = 'Y' THEN p.p_promo_name END) AS latest_active_promo,
    NTILE(4) OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_quartile
FROM item i
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
WHERE i.i_brand IN ('BrandA', 'BrandB', 'BrandC')
GROUP BY i.i_item_sk, i.i_product_name, i.i_brand, i.i_size
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY profit_quartile, sales_revenue DESC
LIMIT 15
