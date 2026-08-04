WITH returns_enriched AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    cr.cr_returning_hdemo_sk,
    cr.cr_returned_date_sk,
    rc.c_customer_id            AS refunded_customer_id,
    rc.c_birth_year             AS refunded_birth_year,
    rc.c_preferred_cust_flag    AS refunded_pref_flag,
    rcg.c_customer_id           AS returning_customer_id,
    rcg.c_birth_year            AS returning_birth_year,
    rcg.c_preferred_cust_flag   AS returning_pref_flag
  FROM catalog_returns cr
  JOIN customer rc
    ON cr.cr_refunded_customer_sk = rc.c_customer_sk
  JOIN customer rcg
    ON cr.cr_returning_customer_sk = rcg.c_customer_sk
  WHERE cr.cr_return_amount > 100
    AND cr.cr_return_quantity >= 1
    AND cr.cr_returning_hdemo_sk BETWEEN 1000 AND 6000
    AND rc.c_birth_year BETWEEN 1960 AND 1990
    AND rcg.c_preferred_cust_flag = 'Y'
)
SELECT
  re.cr_order_number,
  re.cr_return_amount,
  re.cr_net_loss,
  re.refunded_customer_id,
  re.returning_customer_id,
  re.refunded_birth_year,
  re.returning_birth_year,
  SUM(re.cr_net_loss) OVER (
    PARTITION BY re.returning_customer_id
    ORDER BY re.cr_returned_date_sk
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_net_loss,
  ROW_NUMBER() OVER (
    PARTITION BY re.returning_customer_id
    ORDER BY re.cr_returned_date_sk DESC
  ) AS rn_desc,
  LAG(re.cr_net_loss, 1) OVER (
    PARTITION BY re.returning_customer_id
    ORDER BY re.cr_returned_date_sk
  ) AS prev_net_loss,
  RANK() OVER (ORDER BY re.cr_net_loss DESC) AS net_loss_rank
FROM returns_enriched re
ORDER BY re.cr_net_loss DESC
LIMIT 100
