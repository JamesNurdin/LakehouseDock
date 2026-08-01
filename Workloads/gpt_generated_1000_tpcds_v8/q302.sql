WITH intersect_orders AS (
  SELECT cr_order_number AS order_num FROM catalog_returns
  INTERSECT
  SELECT wr_order_number AS order_num FROM web_returns
),
filtered_catalog AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_fee,
    cr.cr_reversed_charge,
    cr.cr_return_quantity,
    cr.cr_refunded_cdemo_sk,
    cr.cr_refunded_customer_sk,
    cr.cr_order_number,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_dep_count,
    cd.cd_demo_sk
  FROM catalog_returns cr
  JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE cr.cr_fee > 20
    AND cr.cr_reversed_charge < 200
    AND cr.cr_return_quantity BETWEEN 1 AND 10
    AND cd.cd_marital_status IN ('M','S')
    AND cd.cd_dep_count >= 1
    AND cr.cr_refunded_customer_sk IN (
      SELECT wr_refunded_customer_sk FROM web_returns WHERE wr_return_quantity > 5
    )
    AND cr.cr_order_number IN (SELECT order_num FROM intersect_orders)
)
SELECT DISTINCT
  fc.cr_returned_date_sk,
  fc.cr_order_number,
  fc.cr_return_amount,
  fc.cr_fee,
  fc.cr_reversed_charge,
  fc.cd_gender,
  fc.cd_marital_status,
  fc.cd_dep_count,
  fc.rn,
  fc.total_web_return_amt,
  CASE
    WHEN fc.wr_return_amt IS NULL THEN 'No Web Return'
    WHEN fc.wr_return_amt > 100 THEN 'High Web Return'
    ELSE 'Low Web Return'
  END AS web_return_category
FROM (
  SELECT
    fc.*,
    wr.wr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY fc.cr_refunded_cdemo_sk ORDER BY fc.cr_return_amount DESC) AS rn,
    (SELECT SUM(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_refunded_cdemo_sk = fc.cr_refunded_cdemo_sk) AS total_web_return_amt
  FROM filtered_catalog fc
  LEFT JOIN web_returns wr
    ON wr.wr_refunded_cdemo_sk = fc.cr_refunded_cdemo_sk
    AND wr.wr_return_quantity > 0
  WHERE (wr.wr_fee > 10 OR wr.wr_fee IS NULL)
    AND wr.wr_account_credit < 500
    AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
) AS fc
ORDER BY fc.rn ASC
LIMIT 100
