/*
  Goal: Summarize total sales, refunds, and inventory across stores, promotions, and warehouses for the year 2000, then rank stores by their sales volume.
*/
WITH base AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        w.w_warehouse_id,
        ca.ca_state,
        SUM(ss.ss_net_paid)                     AS total_store_sales,
        SUM(ss.ss_ext_sales_price)               AS total_store_ext_sales,
        SUM(sr.sr_refunded_cash)                AS total_store_refunds,
        SUM(cr.cr_refunded_cash)                 AS total_catalog_refunds,
        SUM(ws.ws_net_paid)                     AS total_web_sales,
        SUM(wr.wr_refunded_cash)                AS total_web_refunds,
        COUNT(DISTINCT ss.ss_ticket_number)     AS store_sales_transactions,
        COUNT(DISTINCT ws.ws_order_number)      AS web_sales_orders,
        AVG(ss.ss_quantity)                     AS avg_store_quantity,
        MIN(sr.sr_return_quantity)              AS min_return_quantity,
        MAX(ws.ws_quantity)                     AS max_web_quantity,
        SUM(inv.inv_quantity_on_hand)            AS total_inventory_on_hand
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_store_sk = s.s_store_sk
     AND sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_addr_sk = ca.ca_address_sk
     AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_refunded_customer_sk = c.c_customer_sk
     AND cr.cr_refunded_addr_sk = ca.ca_address_sk
     AND cr.cr_returning_customer_sk = c.c_customer_sk
     AND cr.cr_returning_addr_sk = ca.ca_address_sk
    JOIN tpcds.inventory inv
      ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
      ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN tpcds.web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_ship_date_sk = d.d_date_sk
     AND ws.ws_bill_customer_sk = c.c_customer_sk
     AND ws.ws_ship_customer_sk = c.c_customer_sk
     AND ws.ws_bill_addr_sk = ca.ca_address_sk
     AND ws.ws_ship_addr_sk = ca.ca_address_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
     AND ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_refunded_customer_sk = c.c_customer_sk
     AND wr.wr_refunded_addr_sk = ca.ca_address_sk
     AND wr.wr_returning_customer_sk = c.c_customer_sk
     AND wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE
        d.d_year = 2000
        AND s.s_county = 'Jackson County'
        AND sr.sr_refunded_cash > 500
        AND inv.inv_warehouse_sk = 1
        AND p.p_discount_active = 'Y'
        AND w.w_city = 'Seattle'
    GROUP BY
        d.d_year,
        s.s_store_id,
        s.s_state,
        p.p_promo_id,
        w.w_warehouse_id,
        ca.ca_state
)
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_store_sales DESC) AS store_sales_rank
FROM base
ORDER BY total_store_sales DESC
LIMIT 100
