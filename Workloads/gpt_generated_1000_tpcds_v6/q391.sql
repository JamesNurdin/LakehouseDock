WITH
base_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d_sold.d_year,
        t_sold.t_hour,
        c.c_customer_id,
        c.c_customer_sk
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d_sold.d_year = 2001
),
web_ret AS (
    SELECT
        wr.wr_order_number,
        wr.wr_net_loss,
        r.r_reason_id,
        d_wr.d_year,
        c_ref.c_customer_sk AS refund_customer_sk,
        c_ret.c_customer_sk AS returning_customer_sk
    FROM web_returns wr
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c_ref
        ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret
        ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
    WHERE r.r_reason_id = 'AAAAAAAABAAAAAAA'
),
catalog_ret AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        rr.r_reason_id AS catalog_reason_id,
        cc.cc_class,
        cp.cp_catalog_page_number,
        d_cr.d_year,
        c_ref.c_customer_sk AS refund_customer_sk
    FROM catalog_returns cr
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN reason rr
        ON cr.cr_reason_sk = rr.r_reason_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    WHERE cc.cc_class = 'Small'
),
inventory_daily AS (
    SELECT
        d_inv.d_date_sk,
        d_inv.d_year,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    GROUP BY d_inv.d_date_sk, d_inv.d_year
)
SELECT
    bs.c_customer_id,
    bs.d_year,
    SUM(bs.ws_net_paid) AS total_sales,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_return_loss,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_catalog_return_loss,
    SUM(bs.ws_net_profit) AS total_profit,
    COALESCE(SUM(id.total_qty_on_hand), 0) AS total_quantity_on_hand,
    ROW_NUMBER() OVER (
        PARTITION BY bs.d_year
        ORDER BY
            SUM(bs.ws_net_paid) - COALESCE(SUM(wr.wr_net_loss), 0) - COALESCE(SUM(cr.cr_net_loss), 0) DESC
    ) AS sales_rank
FROM base_sales bs
LEFT JOIN web_ret wr
    ON bs.ws_order_number = wr.wr_order_number
LEFT JOIN catalog_ret cr
    ON bs.ws_bill_customer_sk = cr.refund_customer_sk
LEFT JOIN inventory_daily id
    ON bs.ws_sold_date_sk = id.d_date_sk
GROUP BY
    bs.c_customer_id,
    bs.d_year
HAVING SUM(bs.ws_net_paid) > 1000
ORDER BY sales_rank
LIMIT 50
