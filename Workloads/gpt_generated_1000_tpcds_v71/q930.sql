WITH base AS (
    SELECT
        i.i_category,
        w.w_state,
        td.t_hour,
        ws.ws_net_paid,
        ws.ws_order_number,
        cr.cr_return_amount,
        sr.sr_return_amt,
        p.p_cost,
        ws.ws_sales_price
    FROM tpcds.web_sales ws
    JOIN tpcds.time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td_cr
        ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN tpcds.customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN tpcds.customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    WHERE td.t_hour = 15
      AND i.i_brand = 'BrandA'
      AND p.p_cost > 1000
      AND ws_site.web_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM tpcds.inventory inv_check
          WHERE inv_check.inv_item_sk = i.i_item_sk
            AND inv_check.inv_quantity_on_hand > 0
      )
)
SELECT
    i_category,
    w_state,
    t_hour,
    SUM(ws_net_paid)                     AS total_net_paid,
    COUNT(DISTINCT ws_order_number)      AS order_cnt,
    SUM(cr_return_amount)                AS total_return_amount,
    SUM(sr_return_amt)                   AS total_store_return,
    AVG(p_cost)                          AS avg_promo_cost,
    MIN(ws_sales_price)                  AS min_sales_price,
    MAX(ws_sales_price)                  AS max_sales_price
FROM base
GROUP BY ROLLUP (i_category, w_state, t_hour)
HAVING SUM(ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
