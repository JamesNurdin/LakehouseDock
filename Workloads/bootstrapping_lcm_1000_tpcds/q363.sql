WITH agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        w.w_warehouse_name,
        w.w_state,
        s.s_state AS store_state,
        d_ret.d_year AS return_year,
        d_cp_end.d_quarter_name AS catalog_quarter,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_ret.d_year = 2022
    GROUP BY
        cp.cp_department,
        cp.cp_type,
        w.w_warehouse_name,
        w.w_state,
        s.s_state,
        d_ret.d_year,
        d_cp_end.d_quarter_name
)
SELECT
    cp_department,
    cp_type,
    w_warehouse_name,
    w_state,
    store_state,
    return_year,
    catalog_quarter,
    total_return_amount,
    total_net_loss,
    avg_return_qty,
    return_count,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
