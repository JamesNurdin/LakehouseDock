WITH sr AS (
   SELECT
       sr.sr_returned_date_sk,
       d.d_date,
       sr.sr_item_sk,
       i.i_item_id,
       i.i_product_name,
       sr.sr_return_quantity,
       sr.sr_net_loss,
       r.r_reason_desc AS r_reason_desc
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
     AND r.r_reason_desc LIKE '%damage%'
),
wr AS (
   SELECT
       wr.wr_returned_date_sk,
       d.d_date,
       wr.wr_item_sk,
       i.i_item_id,
       i.i_product_name,
       wr.wr_return_quantity,
       wr.wr_net_loss,
       r.r_reason_desc AS wr_reason_desc
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
     AND r.r_reason_desc LIKE '%damage%'
)
SELECT
   COALESCE(sr.d_date, wr.d_date) AS return_date,
   COALESCE(sr.i_item_id, wr.i_item_id) AS item_id,
   COALESCE(sr.i_product_name, wr.i_product_name) AS product_name,
   SUM(COALESCE(sr.sr_return_quantity, 0) + COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty,
   SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
   CASE
       WHEN SUM(COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) > 0 THEN 'Loss'
       ELSE 'NoLoss'
   END AS loss_flag,
   COUNT(DISTINCT COALESCE(sr.r_reason_desc, wr.wr_reason_desc)) AS distinct_reason_cnt
FROM sr
FULL OUTER JOIN wr
   ON sr.sr_item_sk = wr.wr_item_sk
  AND sr.sr_returned_date_sk = wr.wr_returned_date_sk
WHERE EXISTS (
   SELECT 1
   FROM promotion p
   JOIN item i2 ON p.p_item_sk = i2.i_item_sk
   WHERE i2.i_item_sk = COALESCE(sr.sr_item_sk, wr.wr_item_sk)
     AND p.p_discount_active = 'Y'
)
GROUP BY
   COALESCE(sr.d_date, wr.d_date),
   COALESCE(sr.i_item_id, wr.i_item_id),
   COALESCE(sr.i_product_name, wr.i_product_name)
ORDER BY total_net_loss DESC, return_date
OFFSET 0
FETCH FIRST 100 ROWS ONLY
