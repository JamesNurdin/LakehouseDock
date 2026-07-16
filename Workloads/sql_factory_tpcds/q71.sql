SELECT cs.cs_bill_customer_sk AS bill_customer_id,
       SUM(cs.cs_net_profit) AS total_net_profit,
       SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
       MIN(cs.cs_ext_discount_amt) AS min_discount_per_sale,
       MAX(cs.cs_ext_discount_amt) AS max_discount_per_sale,
       COUNT(*) AS total_transactions,
       SUM(CASE WHEN p.p_channel_radio = 'Y' THEN 1 ELSE 0 END) AS radio_promo_transactions,
       ROUND(100.0 * SUM(CASE WHEN p.p_channel_radio = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_radio_promo,
       COUNT(DISTINCT i.i_category) AS distinct_categories_purchased,
       NTILE(4) OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_quartile
FROM catalog_sales cs
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
GROUP BY cs.cs_bill_customer_sk
HAVING SUM(cs.cs_net_profit) > 20000
ORDER BY total_transactions DESC
LIMIT 25
