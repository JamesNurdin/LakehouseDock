WITH base AS (
  SELECT
    ws.ws_order_number,
    ws.ws_quantity AS ws_quantity,
    ws.ws_net_profit AS ws_net_profit,
    ws.ws_ext_sales_price AS ws_ext_sales_price,
    d_sold.d_year AS sale_year,
    i.i_brand AS i_brand,
    i.i_category AS i_category,
    w.w_warehouse_name AS w_warehouse_name,
    sm.sm_type AS sm_type,
    s.s_state AS s_state,
    inv.inv_quantity_on_hand AS inv_quantity_on_hand,
    cp.cp_type AS cp_type
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
  JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
  LEFT JOIN time_dim t_return
    ON wr.wr_returned_time_sk = t_return.t_time_sk
  LEFT JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
  LEFT JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
  LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
   AND cp.cp_end_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year = 2002
    AND sm.sm_type = 'NEXT DAY'
    AND i.i_brand = 'Brand#23'
    AND s.s_state = 'CA'
    AND inv.inv_quantity_on_hand > 0
),
agg AS (
  SELECT
    sale_year,
    i_brand,
    i_category,
    w_warehouse_name,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand
  FROM base
  GROUP BY sale_year, i_brand, i_category, w_warehouse_name
)
SELECT
  sale_year,
  i_brand,
  i_category,
  w_warehouse_name,
  total_quantity_sold,
  total_net_profit,
  total_sales,
  total_inventory_on_hand,
  RANK() OVER (PARTITION BY sale_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY sale_year, profit_rank
LIMIT 100
