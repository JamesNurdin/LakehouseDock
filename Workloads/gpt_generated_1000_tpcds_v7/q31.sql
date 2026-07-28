WITH
    overall_avg AS (
        SELECT avg(cr_return_amount) AS overall_avg_return_amount
        FROM catalog_returns
    ),
    holiday_agg AS (
        SELECT
            w.w_state AS state,
            r.r_reason_desc AS reason,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            d.d_holiday AS holiday_flag
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_holiday = 'Y'
        GROUP BY w.w_state, r.r_reason_desc, d.d_holiday
    ),
    nonholiday_agg AS (
        SELECT
            w.w_state AS state,
            r.r_reason_desc AS reason,
            SUM(cr.cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt,
            d.d_holiday AS holiday_flag
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_holiday = 'N'
        GROUP BY w.w_state, r.r_reason_desc, d.d_holiday
    )
SELECT
    state,
    reason,
    total_return_amount,
    return_cnt,
    holiday_flag,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_return_amount DESC) AS state_rank,
    (SELECT overall_avg_return_amount FROM overall_avg) AS overall_avg_return_amount
FROM (
    SELECT * FROM holiday_agg
    UNION ALL
    SELECT * FROM nonholiday_agg
) AS combined
ORDER BY state, holiday_flag DESC, state_rank
LIMIT 100
