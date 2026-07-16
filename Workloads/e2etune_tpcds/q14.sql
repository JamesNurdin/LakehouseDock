SELECT ib.ib_income_band_sk,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
       SUM(cs.cs_net_profit) AS total_net_profit,
       AVG(cs.cs_net_profit) AS avg_net_profit,
       SUM(cs.cs_ext_ship_cost) AS total_ship_cost,
       RANK() OVER (ORDER BY AVG(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE cs.cs_ext_ship_cost > 500
  AND cs.cs_sales_price BETWEEN 50 AND 150
  AND cs.cs_ext_tax > 0
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING COUNT(DISTINCT cs.cs_order_number) >= 10
ORDER BY profit_rank
LIMIT 10
