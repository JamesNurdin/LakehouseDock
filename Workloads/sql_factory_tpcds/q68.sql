SELECT cs.cs_bill_customer_sk AS bill_customer_id,
       SUM(cs.cs_net_profit) AS total_net_profit,
       SUM(cs.cs_ext_discount_amt) AS total_discount_amount,
       AVG(cs.cs_ext_discount_amt) AS avg_discount_per_sale,
       COUNT(*) AS total_transactions,
       SUM(CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) AS email_promo_transactions,
       ROUND(100.0 * SUM(CASE WHEN p.p_channel_email = 'Y' THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_email_promo,
       COUNT(DISTINCT i.i_brand) AS distinct_brands_purchased,
       CASE WHEN SUM(cs.cs_net_profit) > 150000 THEN 'Platinum'
            WHEN SUM(cs.cs_net_profit) > 80000 THEN 'Gold'
            WHEN SUM(cs.cs_net_profit) > 30000 THEN 'Silver'
            ELSE 'Bronze' END AS customer_tier,
       DENSE_RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451200
GROUP BY cs.cs_bill_customer_sk
HAVING COUNT(*) >= 10
ORDER BY total_net_profit ASC
LIMIT 15
