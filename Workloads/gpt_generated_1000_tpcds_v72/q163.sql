WITH sales_returns AS (
   SELECT
       ws.ws_order_number,
       ws.ws_quantity,
       ws.ws_net_profit,
       ws.ws_ext_sales_price,
       ws.ws_ship_mode_sk,
       sm.sm_ship_mode_id,
       sm.sm_type,
       sm.sm_carrier,
       hd_bill.hd_vehicle_count,
       hd_bill.hd_dep_count,
       t_sale.t_hour AS sale_hour,
       wr.wr_return_amt,
       wr.wr_return_tax,
       wr.wr_return_quantity,
       wr.wr_reason_sk,
       r.r_reason_desc,
       t_return.t_hour AS return_hour
   FROM web_sales ws
   JOIN time_dim t_sale ON ws.ws_sold_time_sk = t_sale.t_time_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
   JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE t_sale.t_hour BETWEEN 8 AND 17
     AND t_return.t_hour BETWEEN 8 AND 17
     AND hd_bill.hd_vehicle_count > 1
     AND sm.sm_type = 'AIR'
     AND ws.ws_quantity >= 30
     AND ws.ws_net_profit > 0
     AND wr.wr_return_tax > 5
     AND r.r_reason_id LIKE 'AAAA%'
),

sales_agg AS (
   SELECT
       sm.sm_ship_mode_id,
       SUM(ws.ws_ext_sales_price) AS total_sales
   FROM web_sales ws
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   GROUP BY sm.sm_ship_mode_id
),

returns_agg AS (
   SELECT
       sm.sm_ship_mode_id,
       SUM(wr.wr_return_amt) AS total_returns
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   GROUP BY sm.sm_ship_mode_id
),

mode_metrics AS (
   SELECT sm_ship_mode_id, total_sales AS metric, 'sales'   AS metric_type FROM sales_agg
   UNION ALL
   SELECT sm_ship_mode_id, total_returns AS metric, 'returns' AS metric_type FROM returns_agg
)

SELECT
   sr.ws_order_number,
   sr.sale_hour,
   sr.return_hour,
   sr.sm_ship_mode_id,
   sr.sm_type,
   sr.sm_carrier,
   sr.hd_vehicle_count,
   sr.ws_quantity,
   CASE WHEN sr.ws_quantity > 80 THEN 'Large' ELSE 'Regular' END AS quantity_category,
   CASE
       WHEN sr.ws_net_profit > (SELECT avg(ws_net_profit) FROM web_sales) THEN 'Above Avg'
       ELSE 'Below Avg'
   END AS profit_vs_avg,
   mm.metric,
   mm.metric_type,
   RANK() OVER (PARTITION BY sr.sm_type ORDER BY sr.wr_return_amt DESC) AS return_rank
FROM sales_returns sr
LEFT JOIN mode_metrics mm
     ON sr.sm_ship_mode_id = mm.sm_ship_mode_id
ORDER BY sr.sm_type, return_rank
LIMIT 100
