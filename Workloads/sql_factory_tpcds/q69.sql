SELECT cs.cs_bill_customer_sk AS bill_customer_id,
       SUM(cs.cs_net_profit) AS total_net_profit,
       SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
       AVG(cs.cs_ext_discount_amt) AS avg_discount_per_sale,
       COUNT(*) AS total_transactions,
       SUM(CASE WHEN p.p_channel_tv = 'Y' THEN 1 ELSE 0 END) AS tv_promo_transactions,
       SUM(CASE WHEN p.p_channel_tv = 'Y' THEN cs.cs_net_profit ELSE 0 END) AS tv_promo_profit,
       ROUND(100.0 * SUM(CASE WHEN p.p_channel_tv = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_tv_promo,
       COUNT(DISTINCT i.i_category) AS distinct_categories_purchased,
       PERCENT_RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_percent_rank
FROM catalog_sales cs
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
GROUP BY cs.cs_bill_customer_sk
HAVING SUM(cs.cs_ext_discount_amt) > 5000
ORDER BY tv_promo_profit DESC
LIMIT 10
