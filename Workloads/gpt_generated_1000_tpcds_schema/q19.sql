WITH base_join AS (
  SELECT
    wr.wr_order_number,
    wr.wr_return_amt,
    wr.wr_return_quantity,
    wr.wr_return_tax,
    d.d_year,
    cd.cd_gender,
    cd.cd_purchase_estimate,
    r.r_reason_desc,
    c.c_salutation,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY wr.wr_return_amt DESC) AS rn_by_year,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_purchase_rank
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 1912
    AND cd.cd_gender = 'F'
    AND wr.wr_return_amt > 500
),
key_set_a AS (
  SELECT wr_order_number
  FROM web_returns
  WHERE wr_return_tax > 100
),
key_set_b AS (
  SELECT wr_order_number
  FROM web_returns
  WHERE wr_return_amt < 600
),
key_diff AS (
  SELECT wr_order_number FROM key_set_a
  EXCEPT
  SELECT wr_order_number FROM key_set_b
),
excluded_orders AS (
  SELECT wr_order_number
  FROM web_returns
  WHERE wr_return_quantity = 0
)
SELECT
  bj.wr_order_number,
  bj.wr_return_amt,
  bj.wr_return_quantity,
  bj.d_year,
  bj.cd_gender,
  bj.cd_purchase_estimate,
  bj.r_reason_desc,
  bj.c_salutation,
  bj.rn_by_year,
  bj.gender_purchase_rank
FROM base_join bj
JOIN key_diff kd ON bj.wr_order_number = kd.wr_order_number
WHERE bj.wr_order_number NOT IN (SELECT wr_order_number FROM excluded_orders)
ORDER BY bj.d_year DESC, bj.rn_by_year ASC
