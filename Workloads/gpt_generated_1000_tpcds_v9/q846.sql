WITH unnested_returns AS (
    SELECT
        cr.*, 
        -- create a homogeneous array of numeric values from quantity (as double) and amount
        CAST(cr.cr_return_quantity AS double) AS return_quantity_double,
        CAST(cr.cr_return_amount AS double) AS return_amount_double,
        -- expand the array to have one row per metric (quantity and amount)
        u.value AS qty_or_amount,
        u.ordinality AS metric_index
    FROM catalog_returns cr
    CROSS JOIN UNNEST(
        ARRAY[CAST(cr.cr_return_quantity AS double), CAST(cr.cr_return_amount AS double)]
    ) WITH ORDINALITY AS u(value, ordinality)
),
aggregated_returns AS (
    SELECT
        w.w_warehouse_sk,
        r.r_reason_desc,
        SUM(ur.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM unnested_returns ur
    -- join to time dimension (first alias)
    JOIN time_dim td ON ur.cr_returned_time_sk = td.t_time_sk
    -- join to reason dimension
    JOIN reason r ON ur.cr_reason_sk = r.r_reason_sk
    -- join to refunded household demographics
    JOIN household_demographics hd_refunded ON ur.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    -- join to refunded customer address
    JOIN customer_address ca_refunded ON ur.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    -- join to returning household demographics
    JOIN household_demographics hd_returning ON ur.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    -- join to returning customer address
    JOIN customer_address ca_returning ON ur.cr_returning_addr_sk = ca_returning.ca_address_sk
    -- join to warehouse (first alias)
    JOIN warehouse w ON ur.cr_warehouse_sk = w.w_warehouse_sk
    -- join to time dimension again under a second alias
    JOIN time_dim td2 ON ur.cr_returned_time_sk = td2.t_time_sk
    -- join to warehouse again under a second alias
    JOIN warehouse w2 ON ur.cr_warehouse_sk = w2.w_warehouse_sk
    -- semi‑join filter using EXISTS
    WHERE EXISTS (
        SELECT 1 FROM reason r2
        WHERE r2.r_reason_sk = ur.cr_reason_sk
          AND r2.r_reason_desc LIKE '%Did not like%'
    )
    GROUP BY w.w_warehouse_sk, r.r_reason_desc
)
SELECT
    w0.w_warehouse_name,
    agg.r_reason_desc,
    COALESCE(agg.total_return_amount, 0) AS total_return_amount,
    COALESCE(agg.return_cnt, 0) AS return_cnt
FROM warehouse w0
FULL OUTER JOIN aggregated_returns agg
    ON w0.w_warehouse_sk = agg.w_warehouse_sk
ORDER BY w0.w_warehouse_name ASC, agg.r_reason_desc ASC
