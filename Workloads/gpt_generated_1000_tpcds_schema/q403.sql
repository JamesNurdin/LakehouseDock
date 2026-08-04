WITH joined_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_bill_customer_sk,
       ws.ws_ship_customer_sk,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       td.t_time,
       td.t_hour,
       p.p_response_target,
       p.p_channel_tv,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       hd_bill.hd_dep_count AS bill_dep_count,
       hd_bill.hd_vehicle_count AS bill_vehicle_count,
       hd_ship.hd_dep_count AS ship_dep_count,
       hd_ship.hd_vehicle_count AS ship_vehicle_count
   FROM web_sales ws
   JOIN time_dim td
     ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN household_demographics hd_bill
     ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN household_demographics hd_ship
     ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN income_band ib
     ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
   WHERE td.t_time BETWEEN 2 AND 12
     AND p.p_response_target = 1
     AND ib.ib_lower_bound >= 40000
),
filtered_sales AS (
   SELECT *
   FROM joined_data jd
   WHERE jd.ws_bill_customer_sk IN (
         SELECT DISTINCT ws2.ws_bill_customer_sk
         FROM web_sales ws2
         WHERE ws2.ws_quantity > 5
   )
),
agg_by_customer AS (
   SELECT
       ws_bill_customer_sk,
       COUNT(DISTINCT ws_order_number) AS distinct_orders,
       SUM(ws_ext_sales_price) AS total_sales,
       SUM(DISTINCT ws_net_profit) AS distinct_net_profit_sum,
       AVG(ws_quantity) AS avg_quantity
   FROM filtered_sales
   GROUP BY ws_bill_customer_sk
)
SELECT
   AVG(distinct_orders) AS avg_distinct_orders_per_customer,
   COUNT(DISTINCT CASE WHEN total_sales > 1000 THEN ws_bill_customer_sk END) AS customers_high_sales,
   COUNT(DISTINCT CASE WHEN avg_quantity < 2 THEN ws_bill_customer_sk END) AS customers_low_avg_qty
FROM agg_by_customer
WHERE ws_bill_customer_sk IN (
   SELECT ws_bill_customer_sk FROM agg_by_customer
   EXCEPT
   SELECT ws_bill_customer_sk FROM agg_by_customer WHERE total_sales < 500
)
LIMIT 100
