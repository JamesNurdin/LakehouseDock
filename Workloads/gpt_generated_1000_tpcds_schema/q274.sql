WITH base_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cc.cc_name,
    cb.c_customer_id AS bill_customer_id,
    sb.c_customer_id AS ship_customer_id,
    cbd.cd_gender AS bill_gender,
    scd.cd_gender AS ship_gender,
    hbd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM catalog_sales cs
  INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  INNER JOIN customer cb
    ON cs.cs_bill_customer_sk = cb.c_customer_sk
  INNER JOIN customer sb
    ON cs.cs_ship_customer_sk = sb.c_customer_sk
  INNER JOIN customer_demographics cbd
    ON cs.cs_bill_cdemo_sk = cbd.cd_demo_sk
  INNER JOIN customer_demographics scd
    ON cs.cs_ship_cdemo_sk = scd.cd_demo_sk
  INNER JOIN household_demographics hbd
    ON cs.cs_ship_hdemo_sk = hbd.hd_demo_sk
  INNER JOIN income_band ib
    ON hbd.hd_income_band_sk = ib.ib_income_band_sk
  INNER JOIN catalog_returns cr2
    ON cr2.cr_order_number = cs.cs_order_number
),

returns_with_reason AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_fee,
    r.r_reason_desc
  FROM catalog_returns cr
  INNER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
),

sales_with_lateral AS (
  SELECT
    b.*,
    lr.total_return_amount,
    lr.total_fee
  FROM base_sales b
  LEFT JOIN LATERAL (
    SELECT
      sum(cr.cr_return_amount) AS total_return_amount,
      sum(cr.cr_fee) AS total_fee
    FROM catalog_returns cr
    WHERE cr.cr_order_number = b.cs_order_number
  ) lr ON true
),

high_paid AS (
  SELECT cs_order_number
  FROM base_sales
  WHERE cs_net_paid > 5000
),

orders_with_returns AS (
  SELECT DISTINCT cr_order_number AS cs_order_number
  FROM catalog_returns
),

intersect_orders AS (
  SELECT cs_order_number
  FROM high_paid
  INTERSECT
  SELECT cs_order_number
  FROM orders_with_returns
)

SELECT
  swl.cc_name,
  swl.bill_gender,
  swl.ship_gender,
  swl.ib_lower_bound,
  swl.ib_upper_bound,
  SUM(swl.cs_quantity) AS total_quantity,
  SUM(swl.cs_net_paid) AS total_net_paid,
  SUM(swl.total_return_amount) AS total_return_amount,
  SUM(swl.total_fee) AS total_fee
FROM sales_with_lateral swl
INNER JOIN intersect_orders io
  ON swl.cs_order_number = io.cs_order_number
GROUP BY GROUPING SETS (
  (cc_name, bill_gender, ship_gender, ib_lower_bound, ib_upper_bound),
  (cc_name, bill_gender, ib_upper_bound),
  (cc_name)
)
ORDER BY total_net_paid DESC
LIMIT 100
