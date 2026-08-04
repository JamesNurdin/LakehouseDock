WITH
  return_agg AS (
    SELECT
      sr_cdemo_sk,
      SUM(sr_return_amt) AS total_return_amt,
      SUM(sr_refunded_cash) AS total_refunded_cash,
      AVG(sr_return_ship_cost) AS avg_ship_cost,
      COUNT(*) AS cnt_returns
    FROM store_returns
    WHERE sr_return_amt > 10        -- predicate 1
      AND sr_return_tax BETWEEN 0 AND 10   -- predicate 2
      AND sr_return_quantity >= 1         -- predicate 3
      AND sr_fee < 5                      -- predicate 4
      AND sr_store_credit > 0             -- predicate 5
    GROUP BY sr_cdemo_sk
  ),
  demo_filtered AS (
    SELECT
      cd_demo_sk,
      cd_gender,
      cd_marital_status,
      cd_credit_rating,
      cd_purchase_estimate,
      cd_dep_college_count
    FROM customer_demographics
    WHERE cd_credit_rating IN ('Good', 'Low Risk', 'High Risk')   -- predicate 6
      AND cd_purchase_estimate >= 1000                           -- predicate 7
      AND cd_dep_college_count >= 2                               -- predicate 8
      AND cd_gender = 'M'                                          -- predicate 9
      AND cd_marital_status = 'S'                                 -- predicate 10
  )
SELECT *
FROM (
  SELECT
    d.cd_demo_sk,
    d.cd_gender,
    d.cd_credit_rating,
    SUM(r.total_return_amt) AS sum_return_amt,
    SUM(r.total_refunded_cash) AS sum_refunded_cash,
    AVG(r.avg_ship_cost) AS avg_ship_cost,
    COUNT(d.cd_demo_sk) AS demo_count
  FROM demo_filtered d
  RIGHT OUTER JOIN return_agg r
    ON r.sr_cdemo_sk = d.cd_demo_sk
  GROUP BY GROUPING SETS (
    (d.cd_demo_sk, d.cd_gender, d.cd_credit_rating),
    (d.cd_gender, d.cd_credit_rating)
  )
  HAVING SUM(r.total_return_amt) > 1000

  UNION DISTINCT

  SELECT
    d.cd_demo_sk,
    d.cd_gender,
    d.cd_credit_rating,
    SUM(r.total_return_amt) * 1.1 AS sum_return_amt,
    SUM(r.total_refunded_cash) * 1.05 AS sum_refunded_cash,
    AVG(r.avg_ship_cost) * 0.9 AS avg_ship_cost,
    COUNT(d.cd_demo_sk) AS demo_count
  FROM demo_filtered d
  RIGHT OUTER JOIN return_agg r
    ON r.sr_cdemo_sk = d.cd_demo_sk
  WHERE d.cd_purchase_estimate BETWEEN 2000 AND 8000   -- extra filter
  GROUP BY GROUPING SETS (
    (d.cd_demo_sk, d.cd_gender, d.cd_credit_rating),
    (d.cd_gender, d.cd_credit_rating)
  )
  HAVING SUM(r.total_return_amt) > 1500
) AS combined
EXCEPT
SELECT
  d.cd_demo_sk,
  d.cd_gender,
  d.cd_credit_rating,
  SUM(r.total_return_amt) AS sum_return_amt,
  SUM(r.total_refunded_cash) AS sum_refunded_cash,
  AVG(r.avg_ship_cost) AS avg_ship_cost,
  COUNT(d.cd_demo_sk) AS demo_count
FROM demo_filtered d
RIGHT OUTER JOIN return_agg r
  ON r.sr_cdemo_sk = d.cd_demo_sk
WHERE d.cd_credit_rating = 'Unknown'
GROUP BY d.cd_demo_sk, d.cd_gender, d.cd_credit_rating
ORDER BY sum_return_amt DESC
LIMIT 100
