WITH
    td_ss AS (SELECT * FROM time_dim),
    td_sr AS (SELECT * FROM time_dim),
    td_cr AS (SELECT * FROM time_dim),
    td_ws AS (SELECT * FROM time_dim),
    r1   AS (SELECT * FROM reason),
    r2   AS (SELECT * FROM reason),
    c    AS (SELECT * FROM customer)
SELECT
    ss.ss_ticket_number,
    SUM(ss.ss_ext_sales_price)                         AS total_sales,
    COUNT(DISTINCT ss.ss_item_sk)                     AS distinct_items_sold,
    CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    (
        SELECT MAX(cr_inner.cr_return_amount)
        FROM catalog_returns cr_inner
        WHERE cr_inner.cr_order_number = ss.ss_ticket_number
    )                                                   AS max_return_amount
FROM store_sales ss
JOIN c ON ss.ss_customer_sk = c.c_customer_sk
JOIN td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
LEFT JOIN store_returns sr
       ON sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_item_sk      = ss.ss_item_sk
LEFT JOIN r1 ON sr.sr_reason_sk = r1.r_reason_sk
LEFT JOIN td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
LEFT JOIN catalog_returns cr
       ON cr.cr_order_number = ss.ss_ticket_number
LEFT JOIN r2 ON cr.cr_reason_sk = r2.r_reason_sk
LEFT JOIN td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm1 ON cr.cr_ship_mode_sk = sm1.sm_ship_mode_sk
LEFT JOIN warehouse w1 ON cr.cr_warehouse_sk = w1.w_warehouse_sk
LEFT JOIN web_sales ws ON ws.ws_order_number = ss.ss_ticket_number
LEFT JOIN td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
LEFT JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
LEFT JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
WHERE ss.ss_ticket_number IN (
        SELECT cr_order_number FROM catalog_returns
        EXCEPT
        SELECT sr_ticket_number FROM store_returns
      )
  AND ss.ss_sold_date_sk = (
        SELECT MAX(cr_returned_date_sk) FROM catalog_returns
      )
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
          AND sr2.sr_net_loss > 500
      )
GROUP BY ss.ss_ticket_number
HAVING SUM(ss.ss_ext_sales_price) > (
        SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2
      )
UNION
SELECT
    ws.ws_order_number               AS ss_ticket_number,
    SUM(ws.ws_ext_sales_price)       AS total_sales,
    COUNT(DISTINCT ws.ws_item_sk)    AS distinct_items_sold,
    CASE WHEN SUM(ws.ws_net_profit) > 5000 THEN 'PROFITABLE' ELSE 'UNPROFITABLE' END AS loss_category,
    NULL                             AS max_return_amount
FROM web_sales ws
JOIN c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
LEFT JOIN ship_mode sm2 ON ws.ws_ship_mode_sk = sm2.sm_ship_mode_sk
LEFT JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
WHERE ws.ws_order_number NOT IN (SELECT ss_ticket_number FROM store_sales)
GROUP BY ws.ws_order_number
ORDER BY total_sales DESC
LIMIT 100
