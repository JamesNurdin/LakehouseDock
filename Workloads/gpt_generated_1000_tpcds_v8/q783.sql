WITH union_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_call_center_sk,
        cr_reason_sk,
        cr_return_amount
    FROM catalog_returns
    WHERE cr_return_amount > 1000
    UNION
    SELECT
        cr_returned_date_sk,
        cr_returned_time_sk,
        cr_call_center_sk,
        cr_reason_sk,
        cr_return_amount
    FROM catalog_returns
    WHERE cr_return_amount < 200
),
intersect_dates AS (
    SELECT cr_returned_date_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    INTERSECT
    SELECT cr_returned_date_sk
    FROM catalog_returns
    WHERE cr_return_quantity < 5
),
joined AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        r.r_reason_desc,
        td.t_hour,
        td.t_minute,
        td.t_am_pm,
        ur.cr_return_amount,
        RANK() OVER (PARTITION BY cc.cc_call_center_id ORDER BY ur.cr_return_amount DESC) AS amount_rank,
        (
            SELECT max(cr_return_amount)
            FROM catalog_returns cr_max
            WHERE cr_max.cr_call_center_sk = cc.cc_call_center_sk
        ) AS max_return_center,
        lr.sum_return
    FROM union_returns ur
    FULL OUTER JOIN call_center cc
        ON ur.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN reason r
        ON ur.cr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim td
        ON ur.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN LATERAL (
        SELECT sum(cr_return_amount) AS sum_return
        FROM catalog_returns cr2
        WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
    ) lr ON true
    WHERE cc.cc_state = 'CA'
      AND td.t_am_pm = 'PM'
      AND r.r_reason_desc IS NOT NULL
      AND ur.cr_returned_date_sk IN (SELECT cr_returned_date_sk FROM intersect_dates)
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_state,
    r_reason_desc,
    t_hour,
    t_minute,
    t_am_pm,
    cr_return_amount,
    amount_rank,
    max_return_center,
    sum_return
FROM joined
ORDER BY amount_rank ASC, max_return_center DESC
LIMIT 100
