WITH catalog AS (
    SELECT cs.cs_order_number,
           cs.cs_sold_date_sk,
           cs.cs_ship_date_sk,
           cs.cs_warehouse_sk,
           cs.cs_promo_sk,
           cs.cs_call_center_sk,
           cs.cs_catalog_page_sk,
           cs.cs_ship_mode_sk,
           cs.cs_net_profit
    FROM tpcds.catalog_sales cs
),
catalog_ret AS (
    SELECT cr.cr_order_number,
           cr.cr_returned_date_sk,
           cr.cr_warehouse_sk,
           cr.cr_ship_mode_sk,
           cr.cr_net_loss
    FROM tpcds.catalog_returns cr
),
web AS (
    SELECT ws.ws_order_number,
           ws.ws_sold_date_sk,
           ws.ws_warehouse_sk,
           ws.ws_promo_sk,
           ws.ws_net_paid
    FROM tpcds.web_sales ws
),
web_ret AS (
    SELECT wr.wr_order_number,
           wr.wr_returned_date_sk,
           wr.wr_net_loss
    FROM tpcds.web_returns wr
)
SELECT d_sold.d_year               AS d_year,
       p.p_promo_name,
       w.w_warehouse_name,
       cc.cc_name,
       SUM(cat.cs_net_profit)                     AS catalog_sales_profit,
       SUM(COALESCE(ret.cr_net_loss, 0))           AS catalog_returns_loss,
       SUM(ss.ss_net_paid)                        AS store_sales_paid,
       SUM(wb.ws_net_paid)                        AS web_sales_paid,
       SUM(COALESCE(wr_ret.wr_net_loss, 0))       AS web_returns_loss,
       SUM(inv.inv_quantity_on_hand)              AS inventory_on_hand
FROM catalog cat
JOIN tpcds.date_dim d_sold
     ON cat.cs_sold_date_sk = d_sold.d_date_sk                     -- join rule 1
JOIN tpcds.date_dim d_ship
     ON cat.cs_ship_date_sk = d_ship.d_date_sk                     -- join rule 2
JOIN tpcds.promotion p
     ON cat.cs_promo_sk = p.p_promo_sk                             -- join rule 3
JOIN tpcds.warehouse w
     ON cat.cs_warehouse_sk = w.w_warehouse_sk                     -- join rule 4
JOIN tpcds.call_center cc
     ON cat.cs_call_center_sk = cc.cc_call_center_sk               -- join rule 5
JOIN tpcds.catalog_page cp
     ON cat.cs_catalog_page_sk = cp.cp_catalog_page_sk             -- join rule 6
JOIN tpcds.ship_mode sm
     ON cat.cs_ship_mode_sk = sm.sm_ship_mode_sk                   -- join rule 7
LEFT JOIN catalog_ret ret
       ON ret.cr_order_number = cat.cs_order_number
      AND ret.cr_warehouse_sk = cat.cs_warehouse_sk                 -- join rule 8 (catalog_returns ↔ catalog_sales)
JOIN tpcds.store_sales ss
     ON ss.ss_sold_date_sk = d_sold.d_date_sk
    AND ss.ss_promo_sk = p.p_promo_sk                              -- join rule 9 (store_sales ↔ date_dim & promotion)
JOIN web wb
     ON wb.ws_order_number = cat.cs_order_number
    AND wb.ws_sold_date_sk = d_sold.d_date_sk
    AND wb.ws_warehouse_sk = w.w_warehouse_sk                       -- join rule 10 (web_sales ↔ date_dim, warehouse)
LEFT JOIN web_ret wr_ret
       ON wr_ret.wr_order_number = wb.ws_order_number
      AND wr_ret.wr_returned_date_sk = d_sold.d_date_sk              -- join rule 11 (web_returns ↔ web_sales & date_dim)
JOIN tpcds.inventory inv
     ON inv.inv_date_sk = d_sold.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk                     -- join rule 12 (inventory ↔ date_dim & warehouse)
GROUP BY GROUPING SETS (
    (d_sold.d_year, p.p_promo_name),
    (w.w_warehouse_name, cc.cc_name),
    ()
)
ORDER BY d_year NULLS LAST,
         p.p_promo_name NULLS LAST,
         w.w_warehouse_name NULLS LAST,
         cc.cc_name NULLS LAST
