WITH refunded AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_order_number,
    cr.cr_ship_mode_sk,
    cr.cr_refunded_customer_sk,
    cr.cr_refunded_cdemo_sk,
    c.c_last_review_date,
    cd.cd_credit_rating,
    sm.sm_type,
    sm.sm_contract
  FROM catalog_returns cr
  JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE c.c_last_review_date IN (2452318, 2452376)
    AND cr.cr_return_tax > 10
    AND sm.sm_type = 'EXPRESS'
    AND cd.cd_credit_rating = 'Low Risk'
),

returning AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_return_amount,
    cr.cr_return_tax,
    cr.cr_order_number,
    cr.cr_ship_mode_sk,
    cr.cr_returning_customer_sk AS cust_sk,
    cr.cr_returning_cdemo_sk AS demo_sk,
    c.c_last_review_date,
    cd.cd_credit_rating,
    sm.sm_type,
    sm.sm_contract
  FROM catalog_returns cr
  JOIN customer c
    ON cr.cr_returning_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE c.c_last_review_date BETWEEN 2452000 AND 2453000
    AND cr.cr_return_tax BETWEEN 5 AND 20
    AND sm.sm_contract = 'qENFQ'
    AND cd.cd_dep_count >= 2
),

union_set AS (
  SELECT
    cr_order_number,
    cr_return_amount,
    cr_return_tax,
    sm_type,
    cd_credit_rating
  FROM refunded
  UNION
  SELECT
    cr_order_number,
    cr_return_amount,
    cr_return_tax,
    sm_type,
    cd_credit_rating
  FROM returning
),

high_loss AS (
  SELECT cr_order_number
  FROM catalog_returns
  WHERE cr_net_loss > 1000
),

low_loss AS (
  SELECT cr_order_number
  FROM catalog_returns
  WHERE cr_net_loss < 100
),

final_set AS (
  SELECT
    us.sm_type,
    us.cd_credit_rating,
    COUNT(DISTINCT us.cr_order_number) AS distinct_orders,
    SUM(us.cr_return_amount) AS total_return_amount,
    AVG(us.cr_return_tax) AS avg_return_tax,
    MIN(us.cr_return_amount) AS min_return_amount,
    MAX(us.cr_return_amount) AS max_return_amount
  FROM union_set us
  WHERE us.cr_return_tax > (
          SELECT AVG(cr_return_tax)
          FROM catalog_returns
          WHERE cr_return_tax > 0
        )
    AND us.cr_order_number NOT IN (SELECT cr_order_number FROM low_loss)
    AND us.cr_order_number IN (
          SELECT cr_order_number FROM high_loss
          EXCEPT
          SELECT cr_order_number FROM low_loss
        )
  GROUP BY us.sm_type, us.cd_credit_rating
)

SELECT DISTINCT
  sm_type,
  cd_credit_rating,
  distinct_orders,
  total_return_amount,
  avg_return_tax,
  min_return_amount,
  max_return_amount
FROM final_set
ORDER BY total_return_amount DESC
LIMIT 100
