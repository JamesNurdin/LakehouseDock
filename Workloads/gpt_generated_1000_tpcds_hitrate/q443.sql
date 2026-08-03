WITH
  agg_returns AS (
    SELECT
      sr_customer_sk,
      sr_reason_sk,
      SUM(sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM store_returns
    GROUP BY sr_customer_sk, sr_reason_sk
  ),
  recent_year AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2002
  )
SELECT *
FROM (
  SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd1.cd_gender,
    CASE WHEN cd1.cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END AS marital_category,
    r.r_reason_desc,
    d_return.d_date AS return_date,
    agg.total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_return.d_date DESC) AS return_rank
  FROM agg_returns agg
  RIGHT OUTER JOIN customer c
    ON agg.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd1
    ON c.c_current_cdemo_sk = cd1.cd_demo_sk
  JOIN store_returns sr2
    ON c.c_customer_sk = sr2.sr_customer_sk
  JOIN reason r
    ON sr2.sr_reason_sk = r.r_reason_sk
  JOIN date_dim d_return
    ON sr2.sr_returned_date_sk = d_return.d_date_sk
  JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
  JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
  JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
  JOIN date_dim d_extra
    ON c.c_last_review_date = d_extra.d_date_sk
  WHERE EXISTS (
      SELECT 1 FROM reason r2
      WHERE r2.r_reason_sk = r.r_reason_sk
        AND r2.r_reason_desc LIKE '%warranty%'
    )
    AND d_return.d_date_sk IN (SELECT d_date_sk FROM recent_year)
) AS sub1
INTERSECT
SELECT *
FROM (
  SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd1.cd_gender,
    CASE WHEN cd1.cd_education_status = 'College' THEN 'Educated' ELSE 'Other' END AS marital_category,
    r.r_reason_desc,
    d_return.d_date AS return_date,
    agg.total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_return.d_date DESC) AS return_rank
  FROM agg_returns agg
  LEFT JOIN customer c
    ON agg.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd1
    ON c.c_current_cdemo_sk = cd1.cd_demo_sk
  JOIN store_returns sr2
    ON c.c_customer_sk = sr2.sr_customer_sk
  JOIN reason r
    ON sr2.sr_reason_sk = r.r_reason_sk
  JOIN date_dim d_return
    ON sr2.sr_returned_date_sk = d_return.d_date_sk
  JOIN date_dim d_ship
    ON c.c_first_shipto_date_sk = d_ship.d_date_sk
  JOIN date_dim d_sales
    ON c.c_first_sales_date_sk = d_sales.d_date_sk
  JOIN date_dim d_review
    ON c.c_last_review_date = d_review.d_date_sk
  WHERE r.r_reason_desc LIKE '%damaged%'
    AND d_return.d_year = 2002
) AS sub2
LIMIT 100
