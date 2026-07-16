SELECT 
    bd_bill.hd_buy_potential AS bill_buy_potential,
    bd_bill.hd_income_band_sk AS bill_income_band,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(bd_ship.hd_vehicle_count) AS avg_ship_vehicle_count,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN household_demographics bd_bill
  ON cs.cs_bill_hdemo_sk = bd_bill.hd_demo_sk
JOIN household_demographics bd_ship
  ON cs.cs_ship_hdemo_sk = bd_ship.hd_demo_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450826
  AND cs.cs_ship_mode_sk IN (5, 7, 11)
GROUP BY bd_bill.hd_buy_potential, bd_bill.hd_income_band_sk
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_profit DESC
LIMIT 20
