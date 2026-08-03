WITH base AS (
  SELECT
    d.d_year,
    sm.sm_type,
    i.i_category,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(DISTINCT ws.ws_ext_sales_price) AS distinct_ws_sales,
    SUM(cs.cs_net_profit) AS total_profit
  FROM tpcds.date_dim d
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
  FULL OUTER JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_customer_sk = c.c_customer_sk
  JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN tpcds.web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_refunded_customer_sk = c.c_customer_sk
    AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    AND wr.wr_reason_sk = r.r_reason_sk
    AND wr.wr_order_number = ws.ws_order_number
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#12'
    AND sr.sr_return_amt > 100
    AND we.web_state = 'CA'
    AND cs.cs_quantity > 5
  GROUP BY d.d_year, sm.sm_type, i.i_category
)
SELECT
  d_year,
  sm_type,
  i_category,
  distinct_orders,
  distinct_ws_sales,
  total_profit,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM base
ORDER BY d_year, profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
