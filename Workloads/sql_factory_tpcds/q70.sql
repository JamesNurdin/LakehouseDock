SELECT cs.cs_bill_customer_sk AS bill_customer_id,
       SUM(cs.cs_net_profit) AS total_net_profit,
       SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
       AVG(cs.cs_ext_discount_amt) AS avg_discount_per_sale,
       COUNT(*) AS total_transactions,
       SUM(CASE WHEN p.p_channel_catalog = 'Y' THEN 1 ELSE 0 END) AS catalog_promo_transactions,
       ROUND(100.0 * SUM(CASE WHEN p.p_channel_catalog = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_catalog_promo,
       COUNT(DISTINCT i.i_size) AS distinct_sizes_purchased,
       MAX(cs.cs_sold_date_sk) AS last_sale_date_sk,
       CASE WHEN MAX(cs.cs_sold_date_sk) > 2451500 THEN 'Recent' ELSE 'Older' END AS recency_flag
FROM catalog_sales cs
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE cs.cs_ext_tax > 0
GROUP BY cs.cs_bill_customer_sk
HAVING COUNT(*) >= 3
ORDER BY last_sale_date_sk DESC
LIMIT 20
