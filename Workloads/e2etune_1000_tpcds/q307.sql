WITH catalog_agg AS (
  SELECT c.c_customer_sk,
         c.c_birth_year,
         w.w_state,
         SUM(cr.cr_net_loss) AS cat_net_loss,
         SUM(cr.cr_return_amount) AS cat_return_amount,
         COUNT(*) AS cat_return_cnt
  FROM catalog_returns cr
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cr.cr_returned_date_sk BETWEEN 20000101 AND 20001231
    AND w.w_state = 'CA'
    AND cr.cr_reversed_charge > 0
  GROUP BY c.c_customer_sk, c.c_birth_year, w.w_state
),
web_agg AS (
  SELECT c.c_customer_sk,
         c.c_birth_year,
         SUM(wr.wr_net_loss) AS web_net_loss,
         SUM(wr.wr_return_amt) AS web_return_amount,
         COUNT(*) AS web_return_cnt
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE wr.wr_returned_date_sk BETWEEN 20000101 AND 20001231
    AND wr.wr_return_quantity > 0
  GROUP BY c.c_customer_sk, c.c_birth_year
)
SELECT COALESCE(ca.c_customer_sk, wa.c_customer_sk) AS customer_sk,
       COALESCE(ca.c_birth_year, wa.c_birth_year) AS birth_year,
       COALESCE(ca.w_state, 'WEB') AS location,
       COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
       COALESCE(ca.cat_return_amount, 0) + COALESCE(wa.web_return_amount, 0) AS total_return_amount,
       COALESCE(ca.cat_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0) AS total_return_cnt,
       RANK() OVER (ORDER BY (COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) DESC) AS loss_rank
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa ON ca.c_customer_sk = wa.c_customer_sk
WHERE (COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
