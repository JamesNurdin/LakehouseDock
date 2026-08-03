WITH sampled_sales AS (
   SELECT *
   FROM catalog_sales TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
   SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        t.t_hour,
        t.t_minute,
        sm.sm_type,
        w.w_city,
        w.w_country,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        i.inv_quantity_on_hand,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        LAG(cs.cs_net_profit) OVER (PARTITION BY w.w_city ORDER BY cs.cs_sold_date_sk) AS prev_city_profit
   FROM sampled_sales cs
   JOIN time_dim t
     ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd_bill
     ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship
     ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN inventory i
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN warehouse w_inv
     ON i.inv_warehouse_sk = w_inv.w_warehouse_sk
   JOIN warehouse w2
     ON cs.cs_warehouse_sk = w2.w_warehouse_sk
   JOIN ship_mode sm2
     ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
),
agg_data AS (
   SELECT
        w_city,
        w_country,
        profit_category,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_net_profit) AS total_profit,
        AVG(cs_net_profit) AS avg_profit,
        SUM(CASE WHEN profit_category = 'HIGH' THEN cs_net_profit ELSE 0 END) AS high_profit_sum
   FROM joined_data
   GROUP BY w_city, w_country, profit_category
),
filtered_high AS (
   SELECT *
   FROM agg_data
   WHERE total_profit > 5000
),
filtered_low AS (
   SELECT *
   FROM agg_data
   WHERE total_profit <= 5000
)
SELECT *
FROM filtered_high
EXCEPT
SELECT *
FROM filtered_low
LIMIT 100
