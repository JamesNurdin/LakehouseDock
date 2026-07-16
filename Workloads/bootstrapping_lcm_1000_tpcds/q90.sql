WITH agg AS (
    SELECT
        cp.cp_catalog_number                           AS cp_catalog_number,
        cp.cp_catalog_page_number                      AS cp_catalog_page_number,
        cp.cp_department                               AS cp_department,
        cp.cp_type                                     AS cp_type,
        d_start.d_date                                 AS catalog_start_date,
        d_end.d_date                                   AS catalog_end_date,
        ds_store.d_date                                AS store_closed_date,
        r.r_reason_desc                                AS r_reason_desc,
        s.s_store_name                                 AS s_store_name,
        s.s_city                                       AS s_city,
        s.s_state                                      AS s_state,
        dr.d_year                                      AS d_year,
        dr.d_month_seq                                 AS d_month_seq,
        SUM(cr.cr_return_amount)                      AS total_return_amount,
        SUM(cr.cr_return_quantity)                    AS total_return_quantity,
        AVG(cr.cr_return_amount)                      AS avg_return_amount,
        MAX(cr.cr_net_loss)                            AS max_net_loss,
        COUNT(DISTINCT cr.cr_order_number)            AS distinct_orders
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim dr
        ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    CROSS JOIN store s
    JOIN date_dim ds_store
        ON s.s_closed_date_sk = ds_store.d_date_sk
    WHERE cp.cp_type = 'PROMOTION'
    GROUP BY
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_department,
        cp.cp_type,
        d_start.d_date,
        d_end.d_date,
        ds_store.d_date,
        r.r_reason_desc,
        s.s_store_name,
        s.s_city,
        s.s_state,
        dr.d_year,
        dr.d_month_seq
)
SELECT
    cp_catalog_number,
    cp_catalog_page_number,
    cp_department,
    cp_type,
    catalog_start_date,
    catalog_end_date,
    store_closed_date,
    r_reason_desc,
    s_store_name,
    s_city,
    s_state,
    d_year,
    d_month_seq,
    total_return_amount,
    total_return_quantity,
    avg_return_amount,
    max_net_loss,
    distinct_orders,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_return_amount DESC) AS dept_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
