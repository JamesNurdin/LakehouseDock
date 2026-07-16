WITH call_center_dim AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name AS call_center_name,
        d_open.d_date AS open_date,
        d_closed.d_date AS closed_date,
        date_diff('day', d_open.d_date, d_closed.d_date) AS open_to_close_days,
        cc.cc_tax_percentage,
        cc.cc_employees,
        cc.cc_sq_ft
    FROM call_center cc
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_closed
        ON cc.cc_closed_date_sk = d_closed.d_date_sk
),
catalog_agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        cc_dim.cc_call_center_sk,
        cc_dim.call_center_name,
        s.s_store_name,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_return_tax) AS catalog_return_tax,
        cc_dim.open_to_close_days
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN call_center_dim cc_dim
        ON cr.cr_call_center_sk = cc_dim.cc_call_center_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        cc_dim.cc_call_center_sk,
        cc_dim.call_center_name,
        s.s_store_name,
        cc_dim.open_to_close_days
),
web_agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_name,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_return_tax) AS web_return_tax
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        d_ret.d_year,
        d_ret.d_month_seq,
        s.s_store_name
),
combined AS (
    SELECT
        COALESCE(ca.d_year, wa.d_year) AS return_year,
        COALESCE(ca.d_month_seq, wa.d_month_seq) AS month_number,
        ca.call_center_name,
        COALESCE(ca.s_store_name, wa.s_store_name) AS store_name,
        ca.catalog_return_qty,
        ca.catalog_net_loss,
        ca.catalog_return_amount,
        ca.catalog_return_tax,
        wa.web_return_qty,
        wa.web_net_loss,
        wa.web_return_amount,
        wa.web_return_tax,
        (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
        (COALESCE(ca.catalog_return_qty, 0) + COALESCE(wa.web_return_qty, 0)) AS total_return_qty,
        (COALESCE(ca.catalog_return_amount, 0) + COALESCE(wa.web_return_amount, 0)) AS total_return_amount,
        (COALESCE(ca.catalog_return_tax, 0) + COALESCE(wa.web_return_tax, 0)) AS total_return_tax,
        ca.open_to_close_days
    FROM catalog_agg ca
    FULL OUTER JOIN web_agg wa
        ON ca.d_year = wa.d_year
        AND ca.d_month_seq = wa.d_month_seq
        AND ca.s_store_name = wa.s_store_name
)
SELECT
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank,
    return_year,
    month_number,
    call_center_name,
    store_name,
    total_return_qty,
    total_return_amount,
    total_return_tax,
    total_net_loss,
    open_to_close_days
FROM combined
ORDER BY net_loss_rank
LIMIT 20
