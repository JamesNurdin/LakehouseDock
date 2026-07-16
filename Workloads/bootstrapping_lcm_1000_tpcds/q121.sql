WITH return_summary AS (
    SELECT
        s.s_store_id,
        s.s_state,
        dd_return.d_year,
        dd_return.d_month_seq,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS return_order_cnt,
        AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    INNER JOIN date_dim dd_return
        ON cr.cr_returned_date_sk = dd_return.d_date_sk
    INNER JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    INNER JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    INNER JOIN store s
        ON s.s_closed_date_sk = dd_return.d_date_sk
    INNER JOIN date_dim dd_ship
        ON c_refunded.c_first_shipto_date_sk = dd_ship.d_date_sk
    INNER JOIN date_dim dd_sales
        ON c_refunded.c_first_sales_date_sk = dd_sales.d_date_sk
    WHERE dd_return.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_id,
        s.s_state,
        dd_return.d_year,
        dd_return.d_month_seq,
        r.r_reason_desc
)
SELECT
    rs.s_store_id,
    rs.s_state,
    rs.d_year,
    rs.d_month_seq,
    rs.r_reason_desc,
    rs.total_return_amount,
    rs.total_net_loss,
    rs.return_order_cnt,
    rs.avg_return_qty,
    ROW_NUMBER() OVER (PARTITION BY rs.s_store_id, rs.d_year ORDER BY rs.total_net_loss DESC) AS loss_rank_in_year
FROM return_summary rs
WHERE rs.total_return_amount > 500
ORDER BY rs.total_net_loss DESC, rs.s_store_id, rs.d_year, rs.d_month_seq
LIMIT 200
