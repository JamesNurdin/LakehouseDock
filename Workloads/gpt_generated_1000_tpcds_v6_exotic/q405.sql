WITH returns_by_date_gender AS (
   SELECT
       d.d_date AS return_date,
       cd.cd_gender,
       SUM(cr.cr_net_loss) AS net_loss,
       SUM(cr.cr_return_quantity) AS total_quantity,
       COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_date, cd.cd_gender
)
SELECT
    rbg.return_date,
    rbg.cd_gender,
    rbg.net_loss,
    rbg.total_quantity,
    rbg.return_cnt,
    'Holiday_Male' AS segment
FROM returns_by_date_gender rbg
JOIN date_dim d ON rbg.return_date = d.d_date
WHERE rbg.cd_gender = 'M'
  AND d.d_holiday = 'Y'

UNION ALL

SELECT
    rbg.return_date,
    rbg.cd_gender,
    rbg.net_loss,
    rbg.total_quantity,
    rbg.return_cnt,
    'NonHoliday_Female' AS segment
FROM returns_by_date_gender rbg
JOIN date_dim d ON rbg.return_date = d.d_date
WHERE rbg.cd_gender = 'F'
  AND d.d_holiday = 'N'
ORDER BY return_date DESC, segment
