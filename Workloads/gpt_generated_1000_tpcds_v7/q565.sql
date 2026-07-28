WITH
    overnight_returns AS (
        SELECT
            sm.sm_type AS ship_mode_type,
            SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
            COUNT(*) AS return_count
        FROM tpcds.catalog_returns cr
        JOIN tpcds.ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE sm.sm_type = 'OVERNIGHT'
          AND cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100
        GROUP BY sm.sm_type
    ),
    express_returns AS (
        SELECT
            sm.sm_type AS ship_mode_type,
            SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
            COUNT(*) AS return_count
        FROM tpcds.catalog_returns cr
        JOIN tpcds.ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE sm.sm_contract = 'OrDuVy2H'
          AND cr.cr_return_amount > 1000
        GROUP BY sm.sm_type
    )
SELECT ship_mode_type, total_return_amount, return_count
FROM overnight_returns
UNION ALL
SELECT ship_mode_type, total_return_amount, return_count
FROM express_returns
ORDER BY total_return_amount DESC
