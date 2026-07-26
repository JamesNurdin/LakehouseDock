SELECT
    i.i_item_sk,
    i.i_category,
    i.i_brand,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn_cnt,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_ext_sales_price) - SUM(ss.ss_ext_discount_amt) AS net_sales_amount,
    AVG(ss.ss_net_profit) AS avg_profit_per_sale,
    MAX(p.p_promo_name) FILTER (WHERE p.p_discount_active = 'Y') AS active_promo_name,
    ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
FROM item i
LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
WHERE i.i_rec_end_date > CURRENT_DATE - INTERVAL '1' YEAR
GROUP BY i.i_item_sk, i.i_category, i.i_brand
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY net_sales_amount DESC
LIMIT 5
