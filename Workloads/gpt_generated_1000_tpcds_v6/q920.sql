WITH joined_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_current_hdemo_sk,
        c.c_last_review_date,
        t.t_time_sk,
        t.t_time_id,
        t.t_sub_shift,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss AS wr_net_loss
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
       AND cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        t.t_sub_shift = 'morning'
        AND t.t_time_id IN ('AAAAAAAAGAAAAAAA', 'AAAAAAAABAAAAAA')
        AND c.c_current_hdemo_sk IN (2615, 725)
        AND c.c_last_review_date >= 2452400
        AND ss.ss_wholesale_cost > 30
        AND ss.ss_list_price BETWEEN 35 AND 120
        AND (cr.cr_return_amount IS NULL OR cr.cr_return_amount > 5)
        AND (wr.wr_return_amt IS NULL OR wr.wr_return_amt > 5)
)
SELECT
    c_customer_id,
    c_current_hdemo_sk,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(wr_return_amt, 0)) AS total_web_returns,
    SUM(COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_net_loss,
    ROW_NUMBER() OVER (ORDER BY SUM(COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) DESC) AS loss_rank
FROM joined_data
GROUP BY c_customer_id, c_current_hdemo_sk
ORDER BY loss_rank
LIMIT 100
