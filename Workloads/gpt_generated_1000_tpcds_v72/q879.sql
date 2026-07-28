WITH return_base AS (
    SELECT
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        w.w_warehouse_name,
        sm.sm_type AS ship_type,
        r.r_reason_desc,
        cd_refunded.cd_gender AS refunded_gender,
        cd_returning.cd_gender AS returning_gender,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_type
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    WHERE d_ret.d_year = 2001
      AND cp.cp_type = 'Electronics'
)
SELECT
    return_year,
    w_warehouse_name,
    ship_type,
    r_reason_desc,
    SUM(cr_return_quantity) AS total_qty,
    SUM(cr_return_amount)   AS total_amount,
    SUM(cr_net_loss)        AS total_net_loss
FROM return_base
GROUP BY ROLLUP (return_year, w_warehouse_name, ship_type, r_reason_desc)
ORDER BY
    return_year ASC NULLS LAST,
    w_warehouse_name ASC NULLS LAST,
    ship_type ASC NULLS LAST,
    r_reason_desc ASC NULLS LAST
