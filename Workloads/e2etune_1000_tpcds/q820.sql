SELECT sm.sm_type,
       sm.sm_carrier,
       cs.cs_sold_date_sk AS sold_date_key,
       COUNT(*) AS order_count,
       COUNT(DISTINCT cs.cs_bill_customer_sk) AS unique_customers,
       SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
       SUM(cs.cs_net_profit) AS total_profit,
       AVG(cs.cs_ext_discount_amt) AS avg_discount,
       SUM(CASE WHEN cs.cs_quantity > 30 THEN cs.cs_net_paid_inc_ship ELSE 0 END) AS net_paid_high_qty,
       SUM(CASE WHEN cs.cs_quantity <= 30 THEN cs.cs_net_paid_inc_ship ELSE 0 END) AS net_paid_low_qty
FROM catalog_sales cs
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cs.cs_ext_discount_amt > 1000
  AND cs.cs_quantity BETWEEN 20 AND 60
  AND sm.sm_type IN ('AIR', 'GROUND')
GROUP BY sm.sm_type, sm.sm_carrier, cs.cs_sold_date_sk
HAVING SUM(cs.cs_net_profit) > 5000
ORDER BY total_profit DESC
LIMIT 100
