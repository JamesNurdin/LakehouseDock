WITH agg AS (
  SELECT
    t.t_hour,
    t.t_shift,
    bd.hd_vehicle_count AS bill_vehicle_count,
    sd.hd_vehicle_count AS ship_vehicle_count,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amt,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales
  FROM catalog_sales cs
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN household_demographics bd ON cs.cs_bill_hdemo_sk = bd.hd_demo_sk
  JOIN household_demographics sd ON cs.cs_ship_hdemo_sk = sd.hd_demo_sk
  WHERE cs.cs_ext_sales_price > 1000
    AND cs.cs_call_center_sk IN (7, 34)
    AND cs.cs_promo_sk IN (1023, 1057)
    AND cs.cs_list_price BETWEEN 120 AND 190
  GROUP BY t.t_hour, t.t_shift, bd.hd_vehicle_count, sd.hd_vehicle_count
  HAVING SUM(cs.cs_net_profit) > 0
)
SELECT
  t_hour,
  t_shift,
  bill_vehicle_count,
  ship_vehicle_count,
  total_net_profit,
  avg_discount_amt,
  distinct_order_cnt,
  total_sales,
  total_sales / NULLIF(total_net_profit, 0) AS sales_to_profit_ratio,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 50
