WITH sales_agg AS (
    SELECT
        d.d_date,
        rs.ss_store_sk,
        cp.cp_department,
        w.w_warehouse_name,
        r_sr.r_reason_desc AS store_return_reason,
        SUM(rs.ss_ext_sales_price)                         AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0))                 AS total_store_returns,
        SUM(COALESCE(wr.wr_return_amt, 0))                 AS total_web_returns,
        AVG(rs.ss_net_profit)                              AS avg_net_profit,
        COUNT(DISTINCT rs.ss_ticket_number)               AS distinct_tickets,
        MAX(inv.inv_quantity_on_hand)                      AS inventory_qty
    FROM store_sales rs
    JOIN date_dim d     ON rs.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t     ON rs.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON rs.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = rs.ss_item_sk
        AND sr.sr_ticket_number = rs.ss_ticket_number
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d.d_year = 2001
    GROUP BY
        d.d_date,
        rs.ss_store_sk,
        cp.cp_department,
        w.w_warehouse_name,
        r_sr.r_reason_desc
)
SELECT
    s.d_date,
    s.ss_store_sk,
    s.cp_department,
    s.w_warehouse_name,
    s.store_return_reason,
    s.total_sales,
    s.total_store_returns,
    s.total_web_returns,
    s.avg_net_profit,
    s.distinct_tickets,
    s.inventory_qty,
    (
        SELECT AVG(ss_net_profit)
        FROM store_sales
    ) AS overall_avg_net_profit,
    ROW_NUMBER() OVER (PARTITION BY s.ss_store_sk ORDER BY s.total_sales DESC) AS store_sales_rank
FROM sales_agg s
ORDER BY s.total_sales DESC
LIMIT 100
