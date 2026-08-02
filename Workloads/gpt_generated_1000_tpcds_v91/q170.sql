WITH base_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_warehouse_sk,
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_order_number,
        d.d_date,
        d.d_year,
        t.t_hour,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
        AND t.t_hour BETWEEN 8 AND 17
        AND cr.cr_return_quantity > 0
        AND cr.cr_return_amount > 100
        AND d.d_date <= (
            SELECT MAX(d2.d_date)
            FROM date_dim d2
            WHERE d2.d_year = 2000
        )
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp
            WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp.cp_type = 'A'
        )
),
additional_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_warehouse_sk,
        cr.cr_call_center_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_order_number,
        d.d_date,
        d.d_year,
        t.t_hour,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2000
        AND t.t_hour NOT BETWEEN 8 AND 17
        AND cr.cr_return_quantity > 0
        AND cr.cr_return_amount > 100
        AND d.d_date <= (
            SELECT MAX(d2.d_date)
            FROM date_dim d2
            WHERE d2.d_year = 2000
        )
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp
            WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp.cp_type = 'A'
        )
),
combined_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_warehouse_sk,
        cr_call_center_sk,
        cr_return_amount,
        cr_net_loss,
        cr_return_quantity,
        cr_order_number,
        d_date,
        d_year,
        t_hour,
        w_warehouse_name,
        w_city,
        w_state
    FROM base_returns
    UNION ALL
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_warehouse_sk,
        cr_call_center_sk,
        cr_return_amount,
        cr_net_loss,
        cr_return_quantity,
        cr_order_number,
        d_date,
        d_year,
        t_hour,
        w_warehouse_name,
        w_city,
        w_state
    FROM additional_returns
),
agg_returns AS (
    SELECT
        cr.cr_call_center_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM combined_returns cr
    GROUP BY cr.cr_call_center_sk
)
SELECT
    COALESCE(cc.cc_name, 'No Call Center') AS call_center_name,
    COALESCE(cc.cc_state, 'N/A') AS call_center_state,
    ar.total_return_amount,
    ar.total_net_loss,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(cc.cc_state, 'N/A')
        ORDER BY ar.total_net_loss DESC
    ) AS rn_state,
    SUM(ar.total_net_loss) OVER (
        PARTITION BY COALESCE(cc.cc_state, 'N/A')
        ORDER BY ar.total_net_loss DESC
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_net_loss_3
FROM agg_returns ar
FULL OUTER JOIN call_center cc
    ON ar.cr_call_center_sk = cc.cc_call_center_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM call_center cc_ex
    WHERE cc_ex.cc_call_center_sk = ar.cr_call_center_sk
      AND cc_ex.cc_state = 'TX'
)
ORDER BY ar.total_net_loss DESC
LIMIT 100
