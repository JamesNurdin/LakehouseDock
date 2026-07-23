WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        ca.ca_address_sk,
        ca.ca_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        cr.cr_return_amount,
        cr.cr_store_credit,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        sm.sm_type,
        w.w_warehouse_name,
        cp.cp_department,
        ws.web_name
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
)
SELECT
    d_year,
    d_month_seq,
    ca_state,
    sm_type,
    w_warehouse_name,
    cp_department,
    web_name,
    SUM(ss_sales_price) AS total_sales_price,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(sr_return_amt) AS total_store_return_amount,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(wr_return_amt) AS total_web_return_amount,
    SUM(inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'Overall Profit' ELSE 'Overall Loss' END AS profit_category
FROM base
WHERE d_year = 2001
  AND d_month_seq = 12
  AND ca_state = 'CA'
  AND sm_type = 'AIR'
GROUP BY d_year, d_month_seq, ca_state, sm_type, w_warehouse_name, cp_department, web_name

UNION ALL

SELECT
    d_year,
    d_month_seq,
    ca_state,
    sm_type,
    w_warehouse_name,
    cp_department,
    web_name,
    SUM(ss_sales_price) * 0.9 AS total_sales_price_adj,
    SUM(ss_net_profit) * 0.9 AS total_net_profit_adj,
    SUM(sr_return_amt) * 0.9 AS total_store_return_amount_adj,
    SUM(cr_return_amount) * 0.9 AS total_catalog_return_amount_adj,
    SUM(wr_return_amt) * 0.9 AS total_web_return_amount_adj,
    SUM(inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
    CASE WHEN SUM(ss_net_profit) * 0.9 > 0 THEN 'Adjusted Profit' ELSE 'Adjusted Loss' END AS profit_category
FROM base
WHERE d_year = 2002
  AND d_month_seq = 1
  AND ca_state = 'NY'
  AND sm_type = 'GROUND'
GROUP BY d_year, d_month_seq, ca_state, sm_type, w_warehouse_name, cp_department, web_name
ORDER BY d_year, d_month_seq, ca_state
LIMIT 100
