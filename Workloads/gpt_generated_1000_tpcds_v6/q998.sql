WITH ws_base AS (
   SELECT
       w.w_warehouse_sk,
       w.w_warehouse_name,
       w.w_zip,
       d_ws.d_year,
       sm.sm_code,
       p.p_promo_name,
       cd.cd_credit_rating,
       hd.hd_vehicle_count,
       ws.ws_ext_sales_price,
       ws.ws_quantity,
       ws.ws_net_profit
   FROM web_sales ws
   JOIN date_dim d_ws
     ON ws.ws_sold_date_sk = d_ws.d_date_sk
   JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN ship_mode sm
     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd
     ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN time_dim t
     ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE ws.ws_ext_sales_price > 100
     AND ws.ws_quantity >= 2
     AND sm.sm_code = 'AIR'
     AND d_ws.d_year = 2001
     AND cd.cd_credit_rating = 'Good'
     AND w.w_zip LIKE '58%'
),

inv_base AS (
   SELECT
       w.w_warehouse_sk,
       d_inv.d_year,
       SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
   FROM inventory inv
   JOIN date_dim d_inv
     ON inv.inv_date_sk = d_inv.d_date_sk
   JOIN warehouse w
     ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE inv.inv_quantity_on_hand > 0
   GROUP BY w.w_warehouse_sk, d_inv.d_year
),

ws_agg AS (
   SELECT
       ws_base.w_warehouse_sk,
       ws_base.w_warehouse_name,
       ws_base.w_zip,
       ws_base.d_year,
       SUM(ws_base.ws_ext_sales_price) AS total_sales,
       SUM(ws_base.ws_net_profit)      AS total_profit,
       SUM(ws_base.ws_quantity)        AS total_quantity
   FROM ws_base
   GROUP BY ws_base.w_warehouse_sk, ws_base.w_warehouse_name, ws_base.w_zip, ws_base.d_year
),

sr_base AS (
   SELECT
       s.s_store_sk,
       s.s_state,
       d_sr.d_year,
       sr.sr_return_amt,
       sr.sr_return_quantity,
       cd2.cd_dep_count,
       hd2.hd_vehicle_count
   FROM store_returns sr
   JOIN date_dim d_sr
     ON sr.sr_returned_date_sk = d_sr.d_date_sk
   JOIN time_dim t_sr
     ON sr.sr_return_time_sk = t_sr.t_time_sk
   JOIN store s
     ON sr.sr_store_sk = s.s_store_sk
   JOIN customer_demographics cd2
     ON sr.sr_cdemo_sk = cd2.cd_demo_sk
   JOIN household_demographics hd2
     ON sr.sr_hdemo_sk = hd2.hd_demo_sk
   WHERE sr.sr_return_quantity > 0
     AND sr.sr_return_amt > 0
     AND s.s_state = 'CA'
     AND cd2.cd_dep_count = 0
),

sr_agg AS (
   SELECT
       s_store_sk,
       d_year,
       SUM(sr_return_amt)      AS total_return_amount_store,
       SUM(sr_return_quantity) AS total_return_qty_store
   FROM sr_base
   GROUP BY s_store_sk, d_year
),

wr_base AS (
   SELECT
       ws.ws_warehouse_sk,
       d_wr.d_year,
       SUM(wr.wr_return_amt)      AS total_return_amount_web,
       SUM(wr.wr_return_quantity) AS total_return_qty_web
   FROM web_returns wr
   JOIN web_sales ws
     ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
   JOIN date_dim d_wr
     ON wr.wr_returned_date_sk = d_wr.d_date_sk
   JOIN time_dim t_wr
     ON wr.wr_returned_time_sk = t_wr.t_time_sk
   GROUP BY ws.ws_warehouse_sk, d_wr.d_year
)

SELECT
    ws.w_warehouse_name,
    ws.d_year,
    ws.total_sales,
    inv.total_inventory_qty,
    sr.total_return_amount_store,
    wr.total_return_amount_web,
    ws.total_profit,
    (ws.total_sales - COALESCE(sr.total_return_amount_store,0) - COALESCE(wr.total_return_amount_web,0)) / NULLIF(inv.total_inventory_qty,0) AS sales_per_inventory,
    ROW_NUMBER() OVER (PARTITION BY ws.d_year ORDER BY ws.total_sales DESC) AS sales_rank,
    DENSE_RANK() OVER (ORDER BY (ws.total_profit - COALESCE(sr.total_return_amount_store,0) - COALESCE(wr.total_return_amount_web,0)) DESC) AS profit_loss_rank,
    CASE
        WHEN (ws.total_profit - COALESCE(sr.total_return_amount_store,0) - COALESCE(wr.total_return_amount_web,0)) > 100000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS profit_category
FROM ws_agg ws
LEFT JOIN inv_base inv
  ON ws.w_warehouse_sk = inv.w_warehouse_sk
 AND ws.d_year = inv.d_year
LEFT JOIN sr_agg sr
  ON ws.d_year = sr.d_year
LEFT JOIN wr_base wr
  ON ws.w_warehouse_sk = wr.ws_warehouse_sk
 AND ws.d_year = wr.d_year
ORDER BY ws.d_year, sales_rank
