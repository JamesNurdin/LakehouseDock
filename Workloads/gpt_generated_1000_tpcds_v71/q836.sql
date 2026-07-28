WITH return_by_reason AS (
    SELECT
        r.r_reason_id,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(cr.cr_return_quantity) AS sum_return_quantity,
        AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
        COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_ship_cost > 50
      AND cr.cr_fee < 500
      AND r.r_reason_desc LIKE '%price%'
    GROUP BY r.r_reason_id, r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > 5000
       AND COUNT(*) >= 10
)
SELECT
    r_reason_id,
    r_reason_desc,
    sum_return_amount,
    sum_return_quantity,
    avg_ship_cost,
    cnt_returns,
    ROW_NUMBER() OVER (ORDER BY sum_return_amount DESC) AS reason_rank,
    AVG(sum_return_amount) OVER () AS avg_sum_return_amount
FROM return_by_reason
ORDER BY reason_rank
