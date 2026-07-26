SELECT
    i.i_item_sk,
    i.i_brand,
    i.i_category,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_tax) AS total_tax,
    SUM(ss.ss_net_paid_inc_tax) AS total_paid_inc_tax,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_sales_price * 0.1 ELSE 0 END) AS promo_discount_estimate,
    PERCENT_RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_percentile
FROM item i
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
WHERE i.i_current_price BETWEEN 10 AND 50
GROUP BY i.i_item_sk, i.i_brand, i.i_category
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY profit_percentile ASC
LIMIT 12
