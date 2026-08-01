WITH cat_sales_agg AS (
  SELECT
    cs.cs_item_sk,
    cs.cs_call_center_sk,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_quantity) AS total_qty
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY cs.cs_item_sk,
           cs.cs_call_center_sk,
           cs.cs_ship_mode_sk,
           cs.cs_warehouse_sk
)
SELECT
  cc.cc_name,
  i.i_category,
  i.i_brand,
  d.d_year,
  sm.sm_type,
  w.w_warehouse_name,
  ws.ws_net_profit,
  cr.cr_return_amount,
  sr.sr_return_amt,
  wr.wr_return_amt,
  inv.inv_quantity_on_hand,
  cs_agg.total_sales,
  cs_agg.total_qty,
  ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY cs_agg.total_sales DESC) AS sales_rank,
  CASE
    WHEN cs_agg.total_sales > 300000 THEN 'High'
    WHEN cs_agg.total_sales > 100000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_tier
FROM
  cat_sales_agg cs_agg
  RIGHT OUTER JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
  JOIN date_dim d
    ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  LEFT JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
   AND sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
  LEFT JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
  LEFT JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  LEFT JOIN web_site web
    ON web.web_open_date_sk = d.d_date_sk
  LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_sold_time_sk = t.t_time_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
   AND ws.ws_web_site_sk = web.web_site_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_item_sk = i.i_item_sk
   AND wr.wr_refunded_addr_sk = ca.ca_address_sk
   AND wr.wr_returning_addr_sk = ca.ca_address_sk
   AND wr.wr_order_number = ws.ws_order_number
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE
  i.i_category = 'Electronics'
  AND cc.cc_market_manager = 'John Doe'
  AND w.w_state = 'TX'
  AND ca.ca_city = 'Oak Ridge'
ORDER BY cs_agg.total_sales DESC
LIMIT 100
