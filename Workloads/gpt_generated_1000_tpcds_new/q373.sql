WITH non_return_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_customer_sk IN (SELECT ss_customer_sk FROM store_sales)
    EXCEPT
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_customer_sk IN (SELECT sr_customer_sk FROM store_returns)
)
SELECT
    cp.cp_department,
    w.w_state,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM date_dim d
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
LEFT JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
   AND i.inv_warehouse_sk = w.w_warehouse_sk
FULL OUTER JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
FULL OUTER JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN time_dim t
    ON t.t_time_sk = cr.cr_returned_time_sk
LEFT JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND cp.cp_department = 'Electronics'
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
    AND ca.ca_country = 'United States'
    AND EXISTS (
        SELECT 1 FROM reason r2
        WHERE r2.r_reason_sk = cr.cr_reason_sk
          AND r2.r_reason_desc = 'Damaged'
    )
    AND c.c_customer_sk IN (SELECT c_customer_sk FROM non_return_customers)
GROUP BY
    cp.cp_department,
    w.w_state
ORDER BY
    total_sales_amount DESC
LIMIT 100
