WITH weekend_returns AS (
  SELECT
    d.d_date AS return_date,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE d.d_weekend = 'Y'
  GROUP BY d.d_date
),
weekday_preferred_returns AS (
  SELECT
    d.d_date AS return_date,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE d.d_weekend = 'N'
    AND c.c_preferred_cust_flag = 'Y'
  GROUP BY d.d_date
)
SELECT *
FROM weekend_returns
UNION ALL
SELECT *
FROM weekday_preferred_returns
ORDER BY return_date DESC
LIMIT 100
