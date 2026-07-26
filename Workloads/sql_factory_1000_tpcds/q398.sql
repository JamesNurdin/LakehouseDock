SELECT cs.cs_item_sk,
       cd.cd_gender,
       SUM(cs.cs_quantity) AS total_sales_qty,
       SUM(cs.cs_ext_sales_price) AS total_sales_revenue,
       SUM(cs.cs_ext_wholesale_cost) AS total_sales_cost,
       SUM(cs.cs_net_profit) AS total_sales_profit,
       COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_qty,
       COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
       SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_return_amt), 0) AS net_profit_after_returns,
       CASE 
           WHEN SUM(cs.cs_ext_sales_price) = 0 THEN NULL
           ELSE (SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_return_amt), 0)) / SUM(cs.cs_ext_sales_price)
       END AS profit_margin,
       DENSE_RANK() OVER (ORDER BY 
           CASE 
               WHEN SUM(cs.cs_ext_sales_price) = 0 THEN 0
               ELSE (SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_return_amt), 0)) / SUM(cs.cs_ext_sales_price)
           END DESC) AS profit_margin_rank,
       CASE 
           WHEN (SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_return_amt), 0)) / NULLIF(SUM(cs.cs_ext_sales_price),0) > 0.2 THEN 'High'
           WHEN (SUM(cs.cs_net_profit) - COALESCE(SUM(sr.sr_return_amt), 0)) / NULLIF(SUM(cs.cs_ext_sales_price),0) > 0.1 THEN 'Medium'
           ELSE 'Low'
       END AS margin_category,
       AVG(s.s_tax_percentage) AS avg_store_tax_percentage
FROM catalog_sales cs
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
  AND sr.sr_item_sk = cs.cs_item_sk
LEFT JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
GROUP BY cs.cs_item_sk, cd.cd_gender
HAVING SUM(cs.cs_ext_sales_price) > 0
ORDER BY profit_margin_rank
LIMIT 10
