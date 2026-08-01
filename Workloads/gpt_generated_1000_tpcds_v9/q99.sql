WITH cr_joins AS (
    SELECT
        cr.cr_order_number,
        d_ret.d_year AS return_year,
        d_ret.d_month_seq AS return_month_seq,
        t_ret.t_hour AS return_hour,
        c_ref.c_customer_sk AS refunded_customer_sk,
        c_ref.c_last_name AS refunded_last_name,
        ca_ref.ca_state AS refunded_state,
        c_ret.c_customer_sk AS returning_customer_sk,
        c_ret.c_last_name AS returning_last_name,
        ca_ret.ca_state AS returning_state,
        cc.cc_name AS call_center_name,
        cp.cp_department AS catalog_department,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name AS warehouse_name,
        r.r_reason_desc AS return_reason,
        cr.cr_net_loss,
        d_open.d_year AS cc_open_year,
        d_closed.d_year AS cc_closed_year,
        d_page_start.d_year AS cp_start_year,
        d_page_end.d_year AS cp_end_year
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_open ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
    JOIN date_dim d_page_start ON cp.cp_start_date_sk = d_page_start.d_date_sk
    JOIN date_dim d_page_end ON cp.cp_end_date_sk = d_page_end.d_date_sk
),
web_distinct_customers AS (
    SELECT DISTINCT wr.wr_refunded_customer_sk AS refunded_customer_sk
    FROM web_returns wr
),
filtered AS (
    SELECT *
    FROM cr_joins crj
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = crj.cr_order_number
    )
    AND NOT EXISTS (
        SELECT 1
        FROM web_distinct_customers wc
        WHERE wc.refunded_customer_sk = crj.refunded_customer_sk
    )
),
agg AS (
    SELECT
        return_year,
        return_month_seq,
        return_reason,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr_order_number) AS distinct_orders,
        AVG(cr_net_loss) AS avg_net_loss
    FROM filtered
    GROUP BY
        return_year,
        return_month_seq,
        return_reason
)
SELECT
    return_year,
    return_month_seq,
    return_reason,
    CASE
        WHEN total_net_loss > 5000 THEN 'High'
        WHEN total_net_loss > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    distinct_orders,
    total_net_loss,
    avg_net_loss
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
