WITH catalog_ret AS (
    SELECT
        'catalog' AS return_source,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND i.i_size = 'large'
      AND hd.hd_vehicle_count > 0
    GROUP BY r.r_reason_desc
    HAVING SUM(cr.cr_return_amount) > 1000
),
web_ret AS (
    SELECT
        'web' AS return_source,
        r.r_reason_desc AS reason,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND i.i_size = 'large'
      AND hd.hd_vehicle_count > 0
    GROUP BY r.r_reason_desc
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT return_source,
       reason,
       total_return_amount
FROM (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
