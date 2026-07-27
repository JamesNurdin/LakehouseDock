-- Goal: Calculate per‑customer, per‑date profit and return metrics, categorize shipping mode, rank customers by total profit, and limit to the top 100 rows.
WITH
    d_sold AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2001
    ),
    d_return AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2001
    ),
    w_cr AS (
        SELECT *
        FROM warehouse
    ),
    w_inv AS (
        SELECT *
        FROM warehouse
    ),
    base AS (
        SELECT
            d_sold.d_date,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            cp.cp_department,
            CASE WHEN sm.sm_type = 'AIR' THEN 'Fast' ELSE 'Standard' END AS shipping_category,
            SUM(ss.ss_net_profit)                         AS total_net_profit,
            SUM(COALESCE(cr.cr_return_amount, 0))          AS total_return_amount,
            COUNT(DISTINCT ss.ss_ticket_number)           AS distinct_tickets
        FROM store_sales ss
        JOIN d_sold      ON ss.ss_sold_date_sk   = d_sold.d_date_sk
        JOIN customer c  ON ss.ss_customer_sk    = c.c_customer_sk
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
           AND sr.sr_item_sk       = ss.ss_item_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_refunded_customer_sk = c.c_customer_sk
        LEFT JOIN d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
        LEFT JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN w_cr
            ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
        LEFT JOIN inventory inv
            ON inv.inv_date_sk = d_sold.d_date_sk
        LEFT JOIN w_inv
            ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
        LEFT JOIN web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
        LEFT JOIN web_site ws
            ON ws.web_open_date_sk = d_sold.d_date_sk
        WHERE EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_customer_sk = c.c_customer_sk
              AND wp2.wp_autogen_flag = 'Y'
        )
        GROUP BY
            d_sold.d_date,
            c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            cp.cp_department,
            CASE WHEN sm.sm_type = 'AIR' THEN 'Fast' ELSE 'Standard' END
    )
SELECT
    b.d_date,
    b.c_customer_id,
    b.c_first_name,
    b.c_last_name,
    b.cp_department,
    b.shipping_category,
    b.total_net_profit,
    b.total_return_amount,
    b.distinct_tickets,
    ROW_NUMBER() OVER (ORDER BY b.total_net_profit DESC) AS profit_rank
FROM base b
ORDER BY b.total_net_profit DESC
LIMIT 100
