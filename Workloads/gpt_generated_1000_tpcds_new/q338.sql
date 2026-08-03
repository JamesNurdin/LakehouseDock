WITH refunded AS (
   SELECT
       cr_refunded_addr_sk AS address_sk,
       cr_warehouse_sk AS warehouse_sk,
       ca_state,
       SUM(cr_return_amt_inc_tax) AS total_return_amount
   FROM catalog_returns
   TABLESAMPLE BERNOULLI (10)
   JOIN customer_address
        ON catalog_returns.cr_refunded_addr_sk = customer_address.ca_address_sk
   WHERE ca_suite_number LIKE 'Suite 4%'
     AND cr_return_amt_inc_tax > 0
   GROUP BY GROUPING SETS (
       (cr_refunded_addr_sk, cr_warehouse_sk, ca_state),
       (cr_refunded_addr_sk, ca_state)
   )
),
returning AS (
   SELECT
       cr_returning_addr_sk AS address_sk,
       cr_warehouse_sk AS warehouse_sk,
       ca_state,
       SUM(cr_return_amt_inc_tax) AS total_return_amount
   FROM catalog_returns
   JOIN customer_address
        ON catalog_returns.cr_returning_addr_sk = customer_address.ca_address_sk
   WHERE ca_zip LIKE '3____'
   GROUP BY GROUPING SETS (
       (cr_returning_addr_sk, cr_warehouse_sk, ca_state),
       (cr_returning_addr_sk, ca_state)
   )
)
SELECT address_sk,
       warehouse_sk,
       ca_state,
       total_return_amount
FROM refunded
EXCEPT
SELECT address_sk,
       warehouse_sk,
       ca_state,
       total_return_amount
FROM returning
ORDER BY address_sk, warehouse_sk
OFFSET 10 ROWS
LIMIT 100
