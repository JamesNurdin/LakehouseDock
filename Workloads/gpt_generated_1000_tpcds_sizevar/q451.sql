WITH joined_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_order_number,
        td.t_hour,
        td.t_minute,
        td.t_second,
        CASE WHEN cr.cr_fee > 50 THEN 'HIGH' ELSE 'LOW' END AS fee_category,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_returned_date_sk ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_ship_cost > 20
      AND cr.cr_fee BETWEEN 10 AND 90
      AND td.t_hour IN (7, 11, 15, 16)
      AND td.t_minute NOT IN (2, 14)
      AND td.t_second <= 14
)
SELECT
    jd.cr_returned_date_sk,
    jd.cr_order_number,
    jd.cr_return_amount,
    jd.fee_category,
    jd.rn
FROM joined_data jd
WHERE jd.cr_order_number NOT IN (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_fee > 80
)
UNION
SELECT
    jd.cr_returned_date_sk,
    jd.cr_order_number,
    jd.cr_return_amount,
    jd.fee_category,
    jd.rn
FROM joined_data jd
WHERE jd.cr_return_amount > 200
ORDER BY cr_return_amount DESC
LIMIT 100
