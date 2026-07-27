WITH customer_catalog AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       SUM(cr.cr_return_amount) AS total_catalog_return_amount,
       SUM(cr.cr_net_loss) AS total_catalog_net_loss,
       COUNT(*) AS catalog_return_cnt
   FROM customer c
   JOIN catalog_returns cr
     ON cr.cr_refunded_customer_sk = c.c_customer_sk
   WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2453000
     AND cr.cr_return_quantity > 1
     AND cr.cr_return_ship_cost > 100
     AND cr.cr_fee < 500
   GROUP BY c.c_customer_sk, c.c_customer_id
),

customer_store AS (
   SELECT
       c.c_customer_sk,
       SUM(sr.sr_return_amt) AS total_store_return_amount,
       SUM(sr.sr_net_loss) AS total_store_net_loss,
       COUNT(*) AS store_return_cnt
   FROM customer c
   JOIN store_returns sr
     ON sr.sr_customer_sk = c.c_customer_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2453000
     AND sr.sr_return_quantity > 1
     AND sr.sr_return_ship_cost > 100
     AND sr.sr_fee < 500
   GROUP BY c.c_customer_sk
),

high_catalog AS (
   SELECT c_customer_sk
   FROM customer_catalog
   WHERE total_catalog_return_amount > 1000
),

high_store AS (
   SELECT c_customer_sk
   FROM customer_store
   WHERE total_store_return_amount > 1000
),

union_high AS (
   SELECT c_customer_sk FROM high_catalog
   UNION
   SELECT c_customer_sk FROM high_store
),

combined AS (
   SELECT
       cc.c_customer_sk,
       cc.c_customer_id,
       cc.total_catalog_return_amount,
       cs.total_store_return_amount,
       (cc.total_catalog_net_loss + cs.total_store_net_loss) AS total_net_loss,
       (cc.catalog_return_cnt + cs.store_return_cnt) AS total_return_cnt
   FROM customer_catalog cc
   JOIN customer_store cs
     ON cc.c_customer_sk = cs.c_customer_sk
   WHERE cc.c_customer_sk IN (SELECT c_customer_sk FROM union_high)
)

SELECT DISTINCT
    c_customer_id,
    total_catalog_return_amount,
    total_store_return_amount,
    total_net_loss,
    total_return_cnt,
    total_net_loss / NULLIF(total_return_cnt, 0) AS avg_loss_per_return
FROM combined
WHERE total_net_loss > 500
  AND total_return_cnt >= 5
  AND total_catalog_return_amount > 200
  AND total_store_return_amount > 200
ORDER BY avg_loss_per_return DESC
LIMIT 100
