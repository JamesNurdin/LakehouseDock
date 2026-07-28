WITH sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) OVER (
            PARTITION BY ss.ss_customer_sk
            ORDER BY ss.ss_sold_date_sk
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
)
SELECT
    d_return.d_date,
    sa.c_first_name,
    sa.c_last_name,
    cp.cp_department,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT sa.ss_ticket_number) AS sales_transactions,
    MAX(sa.cum_net_paid) AS max_cumulative_net_paid
FROM sales_agg sa
JOIN store_returns sr
    ON sa.ss_ticket_number = sr.sr_ticket_number
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN inventory i
    ON i.inv_date_sk = d_return.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_wr
    ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_return.d_date_sk
WHERE d_return.d_year = 2001
GROUP BY
    d_return.d_date,
    sa.c_first_name,
    sa.c_last_name,
    cp.cp_department
ORDER BY d_return.d_date DESC, total_store_return_loss DESC
LIMIT 100
