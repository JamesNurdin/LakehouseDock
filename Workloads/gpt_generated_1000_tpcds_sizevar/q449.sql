WITH
joined AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        d1.d_date,
        d1.d_year,
        t.t_hour,
        s.s_store_name,
        ca.ca_state,
        sr.sr_return_quantity,
        r1.r_reason_desc AS store_return_reason_desc,
        cr.cr_return_amount,
        cp.cp_description,
        cc.cc_name,
        w.w_warehouse_name,
        inv.inv_quantity_on_hand,
        ws.web_name,
        wr.wr_return_quantity,
        r2.r_reason_desc AS web_return_reason_desc
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk                       -- join 1
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk                         -- join 2
    JOIN store s ON ss.ss_store_sk = s.s_store_sk                               -- join 3
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk                -- join 4
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_store_sk = s.s_store_sk                -- join 5
    JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk                         -- join 6
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d1.d_date_sk           -- join 7
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk      -- join 8
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk        -- join 9
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk                  -- join 10
    JOIN inventory inv ON inv.inv_date_sk = d1.d_date_sk
                        AND inv.inv_warehouse_sk = w.w_warehouse_sk      -- join 11
    JOIN web_returns wr ON wr.wr_returned_date_sk = d1.d_date_sk               -- join 12
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk                  -- second alias of date_dim (reuse) join 13
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk                         -- second alias of reason (reuse) join 14
    JOIN web_site ws ON ws.web_open_date_sk = d1.d_date_sk                     -- join 15
),
filtered AS (
    SELECT *
    FROM joined
    WHERE ss_ticket_number NOT IN (
        SELECT sr_ticket_number
        FROM store_returns
        WHERE sr_return_quantity > 0
    )
),
aggregated AS (
    SELECT
        s_store_name,
        d_year,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss_ticket_number) AS num_sales,
        SUM(CASE WHEN sr_return_quantity > 0 THEN sr_return_quantity ELSE 0 END) AS total_return_qty,
        MIN(d_date) AS first_sale_date,
        MAX(d_date) AS last_sale_date
    FROM filtered
    GROUP BY s_store_name, d_year
)
SELECT
    s_store_name,
    d_year,
    total_net_paid,
    num_sales,
    total_return_qty,
    first_sale_date,
    last_sale_date,
    SUM(total_net_paid) OVER (PARTITION BY s_store_name ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid
FROM aggregated
ORDER BY s_store_name ASC, d_year DESC
