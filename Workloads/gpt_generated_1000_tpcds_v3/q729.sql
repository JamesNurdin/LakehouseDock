WITH agg AS (
    SELECT
        p.p_promo_name AS p_promo_name,
        cc.cc_name AS cc_name,
        r.r_reason_desc AS r_reason_desc,
        d_date.d_date AS d_date,
        t_time_sold.t_hour AS t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT cr.cr_order_number) AS return_transactions
    FROM store_sales ss
    JOIN date_dim d_date
        ON ss.ss_sold_date_sk = d_date.d_date_sk
    JOIN time_dim t_time_sold
        ON ss.ss_sold_time_sk = t_time_sold.t_time_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_date.d_date_sk
    JOIN time_dim t_time_return
        ON cr.cr_returned_time_sk = t_time_return.t_time_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_date.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE d_date.d_year = 2001
    GROUP BY
        p.p_promo_name,
        cc.cc_name,
        r.r_reason_desc,
        d_date.d_date,
        t_time_sold.t_hour
)
SELECT
    p_promo_name,
    cc_name,
    r_reason_desc,
    d_date,
    t_hour,
    total_sales,
    total_net_paid,
    total_net_loss,
    sales_transactions,
    return_transactions,
    RANK() OVER (PARTITION BY p_promo_name ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY p_promo_name ORDER BY d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales
FROM agg
ORDER BY total_sales DESC
LIMIT 100
