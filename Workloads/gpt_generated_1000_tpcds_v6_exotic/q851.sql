WITH joined_data AS (
   SELECT
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_return_amt_inc_tax,
       cr.cr_fee,
       cr.cr_return_ship_cost,
       cr.cr_refunded_cash,
       cr.cr_reversed_charge,
       cr.cr_net_loss,
       cr.cr_order_number,
       cr.cr_refunded_hdemo_sk,
       c_ref.c_customer_id   AS refunded_customer_id,
       c_ref.c_salutation    AS refunded_salutation,
       c_ref.c_last_name     AS refunded_last_name,
       c_ret.c_customer_id   AS returning_customer_id,
       c_ret.c_salutation    AS returning_salutation,
       c_ret.c_last_name     AS returning_last_name
   FROM catalog_returns cr
   JOIN customer c_ref
     ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
   JOIN customer c_ret
     ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
   WHERE c_ref.c_salutation = 'Ms.'
     AND c_ref.c_last_name LIKE 'C%'
     AND c_ret.c_salutation = 'Mr.'
     AND cr.cr_refunded_hdemo_sk IN (2051, 6145, 3903)
     AND cr.cr_reversed_charge > 10
     AND cr.cr_net_loss BETWEEN 150 AND 250
     AND cr.cr_return_quantity > 1
)
SELECT
    jd.refunded_customer_id,
    jd.refunded_salutation,
    jd.refunded_last_name,
    COUNT(DISTINCT jd.cr_order_number) AS distinct_orders,
    SUM(jd.cr_return_amount) AS total_return_amount,
    AVG(jd.cr_net_loss) AS avg_net_loss,
    MIN(jd.cr_return_amount) AS min_return_amount,
    MAX(jd.cr_return_amount) AS max_return_amount,
    COUNT(DISTINCT jd.returning_customer_id) AS distinct_returning_customers
FROM joined_data jd
GROUP BY jd.refunded_customer_id, jd.refunded_salutation, jd.refunded_last_name
ORDER BY total_return_amount DESC
LIMIT 100
