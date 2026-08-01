WITH
  sampled_returns AS (
    SELECT
      cr_returned_date_sk,
      cr_ship_mode_sk,
      cr_order_number,
      cr_return_amount,
      cr_return_quantity,
      cr_return_tax,
      cr_return_amt_inc_tax
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_amount > 0
      AND cr_return_quantity >= 1
      AND cr_return_tax IS NOT NULL
  ),

  full_dim AS (
    SELECT
      d.d_date_sk,
      d.d_quarter_name,
      d.d_day_name,
      d.d_year,
      s.sm_ship_mode_sk,
      s.sm_carrier,
      s.sm_contract
    FROM date_dim d
    FULL OUTER JOIN ship_mode s ON 1 = 1
  ),

  order_numbers AS (
    SELECT cr_order_number FROM catalog_returns WHERE cr_return_amount > 0
    EXCEPT
    SELECT cr_order_number FROM catalog_returns WHERE cr_return_quantity = 0
  ),

  aggregated AS (
    SELECT
      fd.d_quarter_name,
      fd.sm_carrier,
      SUM(sr.cr_return_amount) AS total_return_amount,
      SUM(sr.cr_return_quantity) AS total_return_quantity,
      COUNT(*) AS cnt,
      MIN(sr.cr_order_number) AS exemplar_order,
      ROW_NUMBER() OVER (PARTITION BY fd.d_quarter_name ORDER BY SUM(sr.cr_return_amount) DESC) AS rn
    FROM sampled_returns sr
    JOIN full_dim fd
      ON sr.cr_returned_date_sk = fd.d_date_sk
     AND sr.cr_ship_mode_sk = fd.sm_ship_mode_sk
    WHERE fd.d_day_name = 'Monday'
      AND fd.d_year = 1901
      AND fd.sm_contract LIKE 'P7%'
      AND fd.sm_carrier = 'DIAMOND'
    GROUP BY ROLLUP (fd.d_quarter_name, fd.sm_carrier)
    HAVING SUM(sr.cr_return_quantity) > 5
  )
SELECT
  a.d_quarter_name,
  a.sm_carrier,
  a.total_return_amount,
  a.total_return_quantity,
  a.cnt,
  a.rn,
  AVG(a.total_return_amount) OVER (PARTITION BY a.d_quarter_name) AS avg_return_amount_by_quarter
FROM aggregated a
WHERE a.sm_carrier NOT IN (
        SELECT sm_carrier FROM ship_mode WHERE sm_contract = 'YvxVaJI10'
      )
  AND a.d_quarter_name IN ('1901Q2', '1900Q3')
  AND a.total_return_amount > 100
  AND a.rn <= 10
  AND a.exemplar_order IN (SELECT cr_order_number FROM order_numbers)
ORDER BY a.d_quarter_name, a.total_return_amount DESC
LIMIT 100
