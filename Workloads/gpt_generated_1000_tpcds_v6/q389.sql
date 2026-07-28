WITH base AS (
   SELECT
       d.d_date_sk,
       d.d_year,
       sr.sr_return_quantity,
       sr.sr_return_amt,
       s.s_state,
       r.r_reason_id,
       cr.cr_return_amount,
       cr.cr_ship_mode_sk,
       c.c_customer_sk,
       ca.ca_state,
       i.inv_quantity_on_hand,
       ws.ws_order_number,
       ws.ws_net_profit
   FROM tpcds.date_dim d
   JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
   JOIN tpcds.reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN tpcds.customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   JOIN tpcds.customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN tpcds.customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
   JOIN tpcds.warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_order_number = ws.ws_order_number
   JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
   WHERE r.r_reason_id = 'R001'
     AND s.s_state = 'CA'
     AND ca.ca_state = 'CA'
     AND d.d_year = 2001
     AND cr.cr_ship_mode_sk = 9
)
SELECT
    base.d_year,
    base.s_state,
    base.ca_state,
    COUNT(DISTINCT base.ws_order_number) AS orders_count,
    SUM(base.cr_return_amount) AS total_catalog_return_amount,
    SUM(base.sr_return_amt) AS total_store_return_amt,
    SUM(base.ws_net_profit) AS total_web_net_profit,
    AVG(base.inv_quantity_on_hand) AS avg_inventory_qty,
    CASE
        WHEN SUM(base.ws_net_profit) > 1000000 THEN 'HIGH'
        WHEN SUM(base.ws_net_profit) > 500000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM tpcds.catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = base.d_date_sk
    ) AS avg_return_amount_by_date
FROM base
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.web_returns wr3
    WHERE wr3.wr_refunded_customer_sk = base.c_customer_sk
)
GROUP BY base.d_year, base.s_state, base.ca_state, base.d_date_sk
ORDER BY total_web_net_profit DESC
LIMIT 100
