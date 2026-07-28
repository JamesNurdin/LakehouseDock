WITH catalog_returns_agg AS (
   SELECT i.i_item_id AS item_id,
          r.r_reason_desc AS reason,
          SUM(cr.cr_return_amount) AS return_amount
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE r.r_reason_desc LIKE '%defect%'
     AND w.w_country = 'United States'
     AND cr.cr_returned_date_sk BETWEEN 2451000 AND 2452000
     AND EXISTS (
         SELECT 1
         FROM store_sales ss
         JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
         WHERE i2.i_item_id = i.i_item_id
           AND ss.ss_net_profit > 1000
     )
   GROUP BY i.i_item_id, r.r_reason_desc
),
web_returns_agg AS (
   SELECT i.i_item_id AS item_id,
          r.r_reason_desc AS reason,
          SUM(wr.wr_return_amt) AS return_amount
   FROM web_returns wr
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   WHERE r.r_reason_desc LIKE '%defect%'
     AND wr.wr_returned_date_sk BETWEEN 2451000 AND 2452000
     AND EXISTS (
         SELECT 1
         FROM store_sales ss
         JOIN item i2 ON ss.ss_item_sk = i2.i_item_sk
         WHERE i2.i_item_id = i.i_item_id
           AND ss.ss_net_profit > 1000
     )
   GROUP BY i.i_item_id, r.r_reason_desc
)
SELECT item_id,
       reason,
       SUM(return_amount) AS total_return_amount
FROM (
   SELECT item_id, reason, return_amount FROM catalog_returns_agg
   UNION ALL
   SELECT item_id, reason, return_amount FROM web_returns_agg
) AS combined
GROUP BY item_id, reason
ORDER BY total_return_amount DESC
LIMIT 100
