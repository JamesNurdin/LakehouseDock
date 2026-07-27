WITH joined_data AS (
    SELECT
        td.t_hour,
        w.w_warehouse_name,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        wr.wr_account_credit,
        c.c_current_hdemo_sk,
        c.c_email_address,
        ss.ss_quantity,
        w.w_state
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE td.t_time IN (1, 4, 5)
      AND ss.ss_quantity > 2
      AND c.c_email_address LIKE '%@NsX6TyaR3iEKjsqmV2R.org%'
      AND w.w_state = 'CA'
      AND cr.cr_return_amount > 10
      AND wr.wr_account_credit > 100
),
agg_data AS (
    SELECT
        t_hour,
        w_warehouse_name,
        COUNT(DISTINCT ss_ticket_number) AS num_sales,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_return_amount,
        AVG(CASE WHEN cr_return_quantity > 0 THEN cr_return_amount END) AS avg_return_amount,
        SUM(wr_account_credit) AS total_account_credit,
        (SUM(ss_ext_sales_price) - SUM(cr_return_amount) - SUM(wr_account_credit)) AS net_revenue
    FROM joined_data
    GROUP BY t_hour, w_warehouse_name
)
SELECT
    t_hour,
    w_warehouse_name,
    num_sales,
    total_sales,
    total_return_amount,
    avg_return_amount,
    total_account_credit,
    net_revenue,
    SUM(total_sales) OVER (PARTITION BY w_warehouse_name ORDER BY t_hour ROWS UNBOUNDED PRECEDING) AS cumulative_sales_by_warehouse
FROM agg_data
ORDER BY net_revenue DESC
LIMIT 100
