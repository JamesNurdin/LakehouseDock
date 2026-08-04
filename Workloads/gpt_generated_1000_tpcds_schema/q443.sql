WITH
  sample_cs AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
  ),
  intersect_orders AS (
    SELECT cs_order_number
    FROM sample_cs
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
  ),
  except_orders AS (
    SELECT cs_order_number
    FROM sample_cs
    EXCEPT
    SELECT wr_order_number
    FROM web_returns
  ),
  base AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_call_center_sk,
      cs.cs_sold_time_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_hdemo_sk,
      cc.cc_name,
      cc.cc_street_type,
      td_sold.t_meal_time,
      hd_bill.hd_vehicle_count AS bill_vehicle_cnt,
      hd_ship.hd_vehicle_count AS ship_vehicle_cnt,
      hd_returning.hd_dep_count AS returning_dep_cnt,
      td_return.t_sub_shift,
      -- correlated scalar subquery per household
      (SELECT SUM(wr2.wr_return_amt)
         FROM web_returns wr2
        WHERE wr2.wr_returning_hdemo_sk = hd_returning.hd_demo_sk) AS total_return_amt_for_household,
      -- profit category case expression
      CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
      -- explode hours string into array elements
      h_hour
    FROM sample_cs cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td_sold
      ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN household_demographics hd_bill
      ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
      ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_returns wr
      ON cs.cs_order_number = wr.wr_order_number
    JOIN time_dim td_return
      ON wr.wr_returned_time_sk = td_return.t_time_sk
    JOIN household_demographics hd_returning
      ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    -- duplicate joins to increase join count
    JOIN time_dim td_bill_alias
      ON cs.cs_sold_time_sk = td_bill_alias.t_time_sk
    JOIN household_demographics hd_bill2
      ON cs.cs_bill_hdemo_sk = hd_bill2.hd_demo_sk
    -- unnest the hours string (e.g., "08:00-17:00") into separate tokens
    CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t (h_hour)
    WHERE cc.cc_rec_end_date = DATE '2001-12-31'
  )
SELECT
  b.cc_name,
  b.t_meal_time,
  b.profit_category,
  SUM(b.cs_net_profit) AS total_net_profit,
  AVG(b.cs_quantity) AS avg_quantity,
  MAX(b.total_return_amt_for_household) AS max_return_amt,
  COUNT(DISTINCT b.cs_order_number) AS order_cnt,
  COUNT(DISTINCT i.cs_order_number) AS intersect_order_cnt,
  COUNT(DISTINCT e.cs_order_number) AS except_order_cnt
FROM base b
LEFT JOIN intersect_orders i
  ON b.cs_order_number = i.cs_order_number
LEFT JOIN except_orders e
  ON b.cs_order_number = e.cs_order_number
GROUP BY
  b.cc_name,
  b.t_meal_time,
  b.profit_category
ORDER BY total_net_profit DESC
LIMIT 100
