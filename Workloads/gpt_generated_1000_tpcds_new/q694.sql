WITH cust_loss AS (
   SELECT cr_returning_customer_sk AS cust_sk,
          SUM(cr_net_loss) AS total_loss,
          COUNT(*) AS return_cnt
   FROM catalog_returns
   WHERE regexp_like(CAST(cr_fee AS varchar), '^[0-9]{2}\\.[0-9]{2}$')
   GROUP BY cr_returning_customer_sk
),
time_amount AS (
   SELECT cr_returned_time_sk AS time_sk,
          SUM(cr_return_amount) AS total_amount
   FROM catalog_returns
   WHERE cr_return_ship_cost > 0
   GROUP BY cr_returned_time_sk
),
intersect_custs AS (
   SELECT cr_returning_customer_sk AS cust_sk
   FROM catalog_returns
   WHERE cr_fee > 20
   INTERSECT
   SELECT c_customer_sk
   FROM customer
   WHERE c_birth_country LIKE 'U%'
),
union_losses AS (
   SELECT cust_sk, total_loss
   FROM cust_loss
   UNION
   SELECT cr_refunded_customer_sk AS cust_sk, SUM(cr_net_loss) AS total_loss
   FROM catalog_returns
   WHERE cr_return_quantity > 1
   GROUP BY cr_refunded_customer_sk
)
SELECT
   c.c_customer_id,
   CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
   cl.total_loss,
   cl.return_cnt,
   sm.sm_carrier,
   SUBSTR(sm.sm_contract, 1, 5) AS contract_prefix,
   REGEXP_EXTRACT(sm.sm_contract, '(\\d{2})$') AS contract_suffix_digits,
   t.t_hour,
   t.t_meal_time,
   ta.total_amount
FROM union_losses ul
JOIN cust_loss cl ON ul.cust_sk = cl.cust_sk
JOIN customer c ON cl.cust_sk = c.c_customer_sk
JOIN catalog_returns cr ON cl.cust_sk = cr.cr_returning_customer_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN time_amount ta ON t.t_time_sk = ta.time_sk
WHERE EXISTS (
      SELECT 1
      FROM catalog_returns cr2
      WHERE cr2.cr_returning_customer_sk = ul.cust_sk
        AND cr2.cr_return_quantity > 5
   )
  AND sm.sm_carrier LIKE 'R%'
  AND regexp_like(c.c_last_name, '^[A-M].*')
  AND ul.cust_sk IN (SELECT cust_sk FROM intersect_custs)
ORDER BY cl.total_loss DESC, c.c_customer_id
LIMIT 100
