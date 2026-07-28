WITH catalog_ret AS (
   SELECT
       d.d_year AS year,
       d.d_month_seq AS month_seq,
       'Catalog' AS return_channel,
       cr.cr_return_amount AS return_amount,
       cr.cr_net_loss AS net_loss,
       CASE WHEN cr.cr_return_amount > 1000 THEN 'Large' ELSE 'Small' END AS size_flag
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND i.i_brand = 'Brand#12'
),
store_ret AS (
   SELECT
       d.d_year AS year,
       d.d_month_seq AS month_seq,
       'Store' AS return_channel,
       sr.sr_return_amt AS return_amount,
       sr.sr_net_loss AS net_loss,
       CASE WHEN sr.sr_return_amt > 1000 THEN 'Large' ELSE 'Small' END AS size_flag
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE d.d_year BETWEEN 2000 AND 2002
     AND i.i_brand = 'Brand#12'
)
SELECT
   year,
   month_seq,
   return_channel,
   SUM(return_amount) AS total_return_amount,
   SUM(net_loss) AS total_net_loss,
   CASE WHEN SUM(return_amount) > 5000 THEN 'High' ELSE 'Moderate' END AS amount_category
FROM (
   SELECT year, month_seq, return_channel, return_amount, net_loss FROM catalog_ret
   UNION ALL
   SELECT year, month_seq, return_channel, return_amount, net_loss FROM store_ret
) u
GROUP BY year, month_seq, return_channel
ORDER BY year DESC, month_seq, return_channel
LIMIT 100
