WITH base AS (
    SELECT
        d.d_year,
        cp.cp_department,
        wp.wp_type,
        r.r_reason_desc,
        ws.ws_net_paid_inc_tax,
        cs.cs_net_paid_inc_ship,
        sr.sr_return_amt_inc_tax,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        ws.ws_order_number,
        cs.cs_order_number,
        sr.sr_ticket_number,
        cr.cr_order_number
    FROM date_dim d
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
       AND cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
       AND cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
       AND cr.cr_order_number = cs.cs_order_number
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
       AND r.r_reason_sk = cr.cr_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cp.cp_department = 'Sports'
      AND cs.cs_quantity >= 2
      AND ws.ws_net_paid_inc_tax > 5000.00
      AND inv.inv_quantity_on_hand < 100
      AND r.r_reason_desc = 'Customer not satisfied'
      AND wp.wp_type = 'Content'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_returned_date_sk = d.d_date_sk
            AND sr2.sr_return_amt_inc_tax > 2000.00
      )
)
SELECT
    d_year,
    cp_department,
    wp_type,
    r_reason_desc,
    SUM(ws_net_paid_inc_tax) AS total_web_net_paid_inc_tax,
    AVG(ws_net_paid_inc_tax) AS avg_web_net_paid_inc_tax,
    SUM(cs_net_paid_inc_ship) AS total_catalog_net_paid_inc_ship,
    SUM(sr_return_amt_inc_tax) AS total_store_return_amt_inc_tax,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT ws_order_number) AS web_order_count,
    COUNT(DISTINCT cs_order_number) AS catalog_order_count,
    COUNT(DISTINCT sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT cr_order_number) AS catalog_return_count
FROM base
GROUP BY d_year, cp_department, wp_type, r_reason_desc
ORDER BY total_web_net_paid_inc_tax DESC
LIMIT 100
