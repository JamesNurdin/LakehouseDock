WITH
ws_joined AS (
   SELECT
       ws.ws_order_number,
       ws.ws_item_sk,
       ws.ws_bill_customer_sk,
       ws.ws_sold_time_sk,
       ws.ws_quantity,
       ws.ws_ext_sales_price,
       ws.ws_net_profit,
       c.c_first_name,
       c.c_last_name,
       hd.hd_income_band_sk,
       ib.ib_lower_bound,
       i.i_category,
       w.w_warehouse_id,
       w.w_warehouse_sq_ft,
       td.t_hour,
       ARRAY[ws.ws_quantity, ws.ws_ext_sales_price] AS metrics
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2451912 AND 2451915
     AND i.i_category_id IN (2, 3, 6)
     AND w.w_warehouse_sq_ft > 500000
     AND ib.ib_lower_bound >= 50000
     AND td.t_hour BETWEEN 8 AND 20
     AND ws.ws_ext_sales_price > 100.00
),
sr_joined AS (
   SELECT
       sr.sr_ticket_number,
       sr.sr_item_sk,
       sr.sr_customer_sk,
       sr.sr_return_time_sk,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       c.c_first_name,
       c.c_last_name,
       hd.hd_income_band_sk,
       ib.ib_upper_bound,
       i.i_category,
       td.t_hour,
       ARRAY[sr.sr_return_quantity, sr.sr_return_amt] AS ret_metrics
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2451915
     AND i.i_category_id = 6
     AND ib.ib_upper_bound <= 150000
     AND td.t_hour BETWEEN 10 AND 22
     AND sr.sr_return_quantity > 0
     AND sr.sr_return_amt > 20.00
),
ws_unnested AS (
   SELECT
       ws_order_number,
       metric,
       ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY metric DESC) AS metric_rank
   FROM ws_joined
   CROSS JOIN UNNEST(ws_joined.metrics) AS t(metric)
),
common_items AS (
   SELECT ws_item_sk AS item_sk FROM ws_joined
   INTERSECT
   SELECT sr_item_sk FROM sr_joined
),
full_item_flow AS (
   SELECT
       COALESCE(ws.ws_item_sk, sr.sr_item_sk) AS item_sk,
       ws.ws_order_number,
       ws.ws_ext_sales_price,
       sr.sr_return_amt,
       ws.ws_quantity,
       sr.sr_return_quantity
   FROM ws_joined ws
   FULL OUTER JOIN sr_joined sr
       ON ws.ws_item_sk = sr.sr_item_sk
)
SELECT
    fif.item_sk,
    i.i_category,
    SUM(fif.ws_ext_sales_price) AS total_sales,
    SUM(fif.sr_return_amt) AS total_returns,
    SUM(fif.ws_quantity) AS total_quantity_sold,
    SUM(fif.sr_return_quantity) AS total_quantity_returned,
    RANK() OVER (ORDER BY SUM(fif.ws_ext_sales_price) DESC) AS sales_rank,
    CASE
        WHEN SUM(fif.ws_ext_sales_price) > 100000 THEN 'HIGH'
        WHEN SUM(fif.ws_ext_sales_price) BETWEEN 50000 AND 100000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS sales_level,
    MAX(ua.metric_rank) FILTER (WHERE ua.ws_order_number = fif.ws_order_number) AS top_metric_rank
FROM full_item_flow fif
JOIN item i ON fif.item_sk = i.i_item_sk
LEFT JOIN ws_unnested ua ON ua.ws_order_number = fif.ws_order_number
WHERE fif.item_sk IN (SELECT item_sk FROM common_items)
GROUP BY GROUPING SETS (
    (fif.item_sk, i.i_category),
    (i.i_category)
)
ORDER BY total_sales DESC
LIMIT 100
