WITH refunded_returns AS (
    SELECT DISTINCT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS return_amount,
        cr.cr_refunded_cash AS refunded_cash,
        cd.cd_gender AS gender,
        td.t_hour AS hour,
        td.t_minute AS minute,
        CASE 
            WHEN cr.cr_return_amount >= 1000 THEN 'High'
            WHEN cr.cr_return_amount >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS amount_category
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_reason_sk IN (9, 48, 59)
      AND td.t_hour BETWEEN 8 AND 18
      AND cd.cd_purchase_estimate >= 3000
      AND cd.cd_dep_employed_count > 0
),
returning_returns AS (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS return_amount,
        cr.cr_refunded_cash AS refunded_cash,
        cd.cd_gender AS gender,
        td.t_hour AS hour,
        td.t_minute AS minute,
        CASE 
            WHEN cr.cr_return_amount >= 1000 THEN 'High'
            WHEN cr.cr_return_amount >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS amount_category
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 200
      AND cr.cr_reason_sk NOT IN (13, 56)
      AND td.t_hour BETWEEN 9 AND 17
      AND cd.cd_purchase_estimate >= 4000
      AND cd.cd_dep_employed_count >= 1
)
SELECT
    order_number,
    return_amount,
    refunded_cash,
    gender,
    hour,
    minute,
    amount_category,
    ROW_NUMBER() OVER (PARTITION BY hour ORDER BY return_amount DESC) AS rn_hour,
    RANK() OVER (ORDER BY return_amount DESC) AS overall_rank
FROM (
    SELECT * FROM refunded_returns
    UNION ALL
    SELECT * FROM returning_returns
) AS combined
ORDER BY overall_rank
LIMIT 100
