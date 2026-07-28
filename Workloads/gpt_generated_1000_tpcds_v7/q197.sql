/*
Goal: Analyze the combined financial impact of sales and returns across all channels (catalog sales, catalog returns, store returns, and web sales) by item brand and hour of the day. The query joins every selected table, re‑uses the item and household_demographics dimensions under multiple aliases, and aggregates net profit/loss and transaction counts using a ROLLUP grouping.
*/
SELECT
    i.i_brand AS brand,
    td_cs.t_hour AS hour_of_day,
    SUM(sr.sr_net_loss)           AS store_return_loss,
    SUM(cr.cr_net_loss)           AS catalog_return_loss,
    SUM(cs.cs_net_profit)         AS catalog_sales_profit,
    SUM(ws.ws_net_profit)         AS web_sales_profit,
    COUNT(DISTINCT sr.sr_ticket_number)   AS store_return_cnt,
    COUNT(DISTINCT cr.cr_order_number)   AS catalog_return_cnt,
    COUNT(DISTINCT cs.cs_order_number)   AS catalog_sales_cnt,
    COUNT(DISTINCT ws.ws_order_number)   AS web_sales_cnt
FROM catalog_sales cs
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim td_cs
  ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN household_demographics hd_cs_bill
  ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
JOIN household_demographics hd_cs_ship
  ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
-- Store returns linked through the shared item dimension
JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN time_dim td_sr
  ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN household_demographics hd_sr
  ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
-- Catalog returns linked through item and order number
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_order_number = cs.cs_order_number
JOIN time_dim td_cr
  ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN household_demographics hd_cr_refunded
  ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN household_demographics hd_cr_returning
  ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
-- Web sales linked through the shared item dimension
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN time_dim td_ws
  ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN household_demographics hd_ws_bill
  ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN household_demographics hd_ws_ship
  ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
-- Inventory linked through the same item dimension
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
GROUP BY ROLLUP (i.i_brand, td_cs.t_hour)
ORDER BY i.i_brand, td_cs.t_hour
