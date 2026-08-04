WITH morning_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        td.t_shift,
        td.t_sub_shift
    FROM catalog_returns AS cr
    JOIN time_dim AS td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
      AND td.t_sub_shift = 'morning'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns AS cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_returned_date_sk <> cr.cr_returned_date_sk
      )
),

evening_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        td.t_shift,
        td.t_sub_shift
    FROM catalog_returns AS cr
    JOIN time_dim AS td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_shift = 'third'
      AND td.t_sub_shift = 'evening'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns AS cr2
          WHERE cr2.cr_order_number = cr.cr_order_number
            AND cr2.cr_returned_date_sk <> cr.cr_returned_date_sk
      )
)
SELECT
    cr_returned_date_sk,
    cr_return_amount,
    cr_return_amt_inc_tax,
    t_shift,
    t_sub_shift
FROM morning_returns
UNION ALL
SELECT
    cr_returned_date_sk,
    cr_return_amount,
    cr_return_amt_inc_tax,
    t_shift,
    t_sub_shift
FROM evening_returns
ORDER BY cr_returned_date_sk DESC, cr_return_amount DESC
LIMIT 100
