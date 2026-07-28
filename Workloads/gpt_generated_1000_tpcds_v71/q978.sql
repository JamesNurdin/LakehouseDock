WITH catalog_part AS (
   SELECT
       'Catalog' AS channel,
       i.i_item_id,
       i.i_category,
       SUM(cs.cs_net_paid) AS total_sales,
       COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns,
       CASE WHEN SUM(cs.cs_net_paid) - COALESCE(SUM(cr.cr_return_amount),0) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
   FROM tpcds.catalog_sales cs
   JOIN tpcds.item i
       ON cs.cs_item_sk = i.i_item_sk
   JOIN tpcds.call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN tpcds.warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.household_demographics hd_bill
       ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN tpcds.household_demographics hd_ship
       ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   LEFT JOIN tpcds.catalog_returns cr
       ON cs.cs_order_number = cr.cr_order_number
      AND cr.cr_item_sk = i.i_item_sk
   LEFT JOIN tpcds.reason r
       ON cr.cr_reason_sk = r.r_reason_sk
   GROUP BY i.i_item_id, i.i_category
),
store_web_part AS (
   SELECT
       'StoreWeb' AS channel,
       i2.i_item_id,
       i2.i_category,
       SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_sales,
       COALESCE(SUM(sr.sr_return_amt),0) + COALESCE(SUM(wr.wr_return_amt),0) AS total_returns,
       CASE WHEN (SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid)) - (COALESCE(SUM(sr.sr_return_amt),0) + COALESCE(SUM(wr.wr_return_amt),0)) > 0
            THEN 'Profitable' ELSE 'Loss' END AS profit_status
   FROM tpcds.store_sales ss
   JOIN tpcds.item i2
       ON ss.ss_item_sk = i2.i_item_sk
   JOIN tpcds.household_demographics hd_ss
       ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
   JOIN tpcds.store_returns sr
       ON sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_item_sk = i2.i_item_sk
   JOIN tpcds.reason r_sr
       ON sr.sr_reason_sk = r_sr.r_reason_sk
   JOIN tpcds.web_sales ws
       ON ws.ws_item_sk = i2.i_item_sk
   JOIN tpcds.web_site web_site
       ON ws.ws_web_site_sk = web_site.web_site_sk
   JOIN tpcds.ship_mode sm2
       ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
   JOIN tpcds.warehouse w2
       ON ws.ws_warehouse_sk = w2.w_warehouse_sk
   JOIN tpcds.web_returns wr
       ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = i2.i_item_sk
   JOIN tpcds.reason r_wr
       ON wr.wr_reason_sk = r_wr.r_reason_sk
   GROUP BY i2.i_item_id, i2.i_category
)
SELECT *
FROM catalog_part
UNION ALL
SELECT *
FROM store_web_part
ORDER BY total_sales DESC
LIMIT 100
