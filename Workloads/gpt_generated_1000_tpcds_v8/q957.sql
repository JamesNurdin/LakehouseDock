WITH sampled_returns AS (
   SELECT cr_returned_date_sk,
          cr_returned_time_sk,
          cr_item_sk,
          cr_refunded_customer_sk,
          cr_refunded_cdemo_sk,
          cr_refunded_hdemo_sk,
          cr_refunded_addr_sk,
          cr_returning_customer_sk,
          cr_returning_cdemo_sk,
          cr_returning_hdemo_sk,
          cr_returning_addr_sk,
          cr_call_center_sk,
          cr_catalog_page_sk,
          cr_ship_mode_sk,
          cr_warehouse_sk,
          cr_reason_sk,
          cr_order_number,
          cr_return_quantity,
          cr_return_amount,
          cr_return_tax,
          cr_return_amt_inc_tax,
          cr_fee,
          cr_return_ship_cost,
          cr_refunded_cash,
          cr_reversed_charge,
          cr_store_credit,
          cr_net_loss
   FROM catalog_returns
   TABLESAMPLE BERNOULLI (10)
   WHERE cr_return_tax > 5.0
     AND cr_return_quantity >= 1
     AND cr_returned_date_sk BETWEEN 2450000 AND 2459999
     AND cr_returned_time_sk < 5000
     AND cr_refunded_customer_sk <> cr_returning_customer_sk
     AND cr_fee <= 50.00
),
joined AS (
   SELECT sr.*, r.r_reason_desc, r.r_reason_id
   FROM sampled_returns sr
   JOIN reason r
     ON sr.cr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc LIKE '%size%'
      OR r.r_reason_desc LIKE '%color%'
),
agg AS (
   SELECT
       cr_reason_sk,
       r_reason_desc,
       SUM(cr_return_amount) AS total_return_amount,
       SUM(cr_return_tax) AS total_tax,
       COUNT(*) AS return_cnt
   FROM joined
   GROUP BY ROLLUP (cr_reason_sk, r_reason_desc)
),
high_loss AS (
   SELECT cr_reason_sk
   FROM agg
   WHERE total_return_amount > 5000
),
low_tax AS (
   SELECT cr_reason_sk
   FROM agg
   WHERE total_tax < 20
),
filtered_reason AS (
   SELECT cr_reason_sk
   FROM high_loss
   EXCEPT
   SELECT cr_reason_sk
   FROM low_tax
),
final_agg AS (
   SELECT
       a.cr_reason_sk,
       a.r_reason_desc,
       a.total_return_amount,
       a.total_tax,
       a.return_cnt,
       CASE WHEN a.r_reason_desc IS NULL THEN 'ALL_REASONS' ELSE a.r_reason_desc END AS grp_reason
   FROM agg a
   JOIN filtered_reason fr
     ON a.cr_reason_sk = fr.cr_reason_sk
)
SELECT cr_reason_sk,
       grp_reason,
       total_return_amount,
       total_tax,
       return_cnt
FROM final_agg
WHERE total_return_amount IS NOT NULL
UNION
SELECT cr_reason_sk,
       grp_reason,
       total_return_amount,
       total_tax,
       return_cnt
FROM final_agg
WHERE total_tax IS NOT NULL
ORDER BY total_return_amount DESC
OFFSET 20 LIMIT 100
