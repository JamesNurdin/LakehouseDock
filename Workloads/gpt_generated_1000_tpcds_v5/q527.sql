WITH agg AS (
    SELECT
        w.w_warehouse_id,
        cd.cd_gender,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 1 ELSE 0 END) AS excellent_cnt
    FROM
        store_returns sr
        JOIN customer_demographics cd
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_returns cr
            ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
        JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        sr.sr_fee > 30
        AND sr.sr_return_quantity >= 2
        AND cr.cr_return_amount > 50
        AND cd.cd_gender = 'F'
        AND w.w_state = 'TX'
        AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY
        w.w_warehouse_id,
        cd.cd_gender
)
SELECT
    w_warehouse_id,
    cd_gender,
    total_return_amount,
    return_cnt,
    avg_return_amount,
    excellent_cnt,
    CASE WHEN avg_return_amount > 100 THEN 'High' ELSE 'Low' END AS avg_category
FROM agg
WHERE
    avg_return_amount > 80
    AND excellent_cnt >= 1
ORDER BY
    avg_return_amount DESC,
    w_warehouse_id
