WITH
  web_agg AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_order_number,
      ws.ws_sold_time_sk,
      ws.ws_web_page_sk,
      ws.ws_web_site_sk,
      SUM(ws.ws_net_paid)               AS web_net_paid,
      SUM(ws.ws_ext_sales_price)        AS web_ext_sales_price,
      SUM(ws.ws_ext_ship_cost)          AS web_ext_ship_cost
    FROM web_sales ws
    GROUP BY
      ws.ws_item_sk,
      ws.ws_order_number,
      ws.ws_sold_time_sk,
      ws.ws_web_page_sk,
      ws.ws_web_site_sk
  ),
  web_ret_agg AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_order_number,
      SUM(wr.wr_return_amt)  AS web_return_amt,
      SUM(wr.wr_return_tax) AS web_return_tax,
      r.r_reason_desc        AS web_return_reason
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY
      wr.wr_item_sk,
      wr.wr_order_number,
      r.r_reason_desc
  )
SELECT
  cc.cc_name,
  s.s_store_name,
  webs.web_name,
  td.t_hour,
  SUM(cs.cs_net_paid)                     AS total_sales,
  SUM(cr.cr_return_amount)                AS total_catalog_returns,
  SUM(sr.sr_return_amt)                   AS total_store_returns,
  SUM(COALESCE(wr_agg.web_return_amt, 0)) AS total_web_returns,
  COUNT(DISTINCT cs.cs_order_number)       AS distinct_orders
FROM catalog_sales cs
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
                         AND cr.cr_order_number = cs.cs_order_number
JOIN reason r_cat_ret ON cr.cr_reason_sk = r_cat_ret.r_reason_sk
JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                        AND sr.sr_return_time_sk = td.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_store_ret ON sr.sr_reason_sk = r_store_ret.r_reason_sk
LEFT JOIN web_agg wa ON wa.ws_item_sk = cs.cs_item_sk
                       AND wa.ws_order_number = cs.cs_order_number
LEFT JOIN web_ret_agg wr_agg ON wr_agg.wr_item_sk = cs.cs_item_sk
                               AND wr_agg.wr_order_number = cs.cs_order_number
LEFT JOIN web_page wp ON wa.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site webs ON wa.ws_web_site_sk = webs.web_site_sk
WHERE cc.cc_rec_start_date >= DATE '2001-01-01'
  AND cc.cc_rec_end_date   <= DATE '2003-12-31'
  AND s.s_state = 'CA'
  AND td.t_minute IN (5, 15)
  AND (wr_agg.web_return_reason = 'Damaged Item' OR wr_agg.web_return_reason IS NULL)
GROUP BY ROLLUP (cc.cc_name, s.s_store_name, webs.web_name, td.t_hour)
ORDER BY cc.cc_name, s.s_store_name, webs.web_name, td.t_hour
