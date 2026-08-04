WITH cat_agg AS (
       SELECT
           cr.cr_reason_sk,
           SUM(cr.cr_return_amount) AS cat_total_return_amount,
           SUM(cr.cr_net_loss) AS cat_total_net_loss,
           COUNT(*) AS cat_return_cnt
       FROM catalog_returns cr TABLESAMPLE BERNOULLI (10)
       WHERE cr.cr_return_tax > 30
         AND cr.cr_store_credit < 500
       GROUP BY cr.cr_reason_sk
   ),
   web_agg AS (
       SELECT
           wr.wr_reason_sk,
           SUM(wr.wr_return_amt) AS web_total_return_amount,
           SUM(wr.wr_net_loss) AS web_total_net_loss,
           COUNT(*) AS web_return_cnt
       FROM web_returns wr
       WHERE wr.wr_refunded_cash > 100
         AND wr.wr_return_ship_cost < 1000
       GROUP BY wr.wr_reason_sk
   ),
   union_agg AS (
       SELECT
           r.r_reason_sk,
           r.r_reason_id,
           r.r_reason_desc,
           ca.cat_total_return_amount AS total_return_amount,
           ca.cat_total_net_loss AS total_net_loss,
           ca.cat_return_cnt AS return_cnt,
           'catalog' AS source
       FROM cat_agg ca
       JOIN reason r ON ca.cr_reason_sk = r.r_reason_sk
       UNION DISTINCT
       SELECT
           r.r_reason_sk,
           r.r_reason_id,
           r.r_reason_desc,
           wa.web_total_return_amount,
           wa.web_total_net_loss,
           wa.web_return_cnt,
           'web' AS source
       FROM web_agg wa
       JOIN reason r ON wa.wr_reason_sk = r.r_reason_sk
   ),
   final AS (
       SELECT
           r_reason_sk,
           r_reason_desc,
           source,
           total_return_amount,
           total_net_loss,
           return_cnt,
           CASE
               WHEN total_net_loss > 200 THEN 'High Loss'
               WHEN total_net_loss > 50  THEN 'Medium Loss'
               ELSE 'Low Loss'
           END AS loss_category,
           RANK() OVER (PARTITION BY source ORDER BY total_net_loss DESC) AS loss_rank,
           ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS overall_row_num
       FROM union_agg
       WHERE r_reason_id LIKE 'AAAA%'
   )
SELECT
   r_reason_sk,
   r_reason_desc,
   source,
   total_return_amount,
   total_net_loss,
   return_cnt,
   loss_category,
   loss_rank,
   overall_row_num
FROM final
ORDER BY loss_rank, total_return_amount DESC
LIMIT 100
