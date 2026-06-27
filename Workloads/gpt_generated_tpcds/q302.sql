WITH unified_returns AS (
    SELECT cr_returned_time_sk AS returned_time_sk,
           cr_item_sk AS item_sk,
           cr_reason_sk AS reason_sk,
           cr_net_loss AS net_loss,
           cr_return_quantity AS return_quantity,
           'catalog' AS return_channel
    FROM catalog_returns
    UNION ALL
    SELECT sr_return_time_sk AS returned_time_sk,
           sr_item_sk AS item_sk,
           sr_reason_sk AS reason_sk,
           sr_net_loss AS net_loss,
           sr_return_quantity AS return_quantity,
           'store' AS return_channel
    FROM store_returns
    UNION ALL
    SELECT wr_returned_time_sk AS returned_time_sk,
           wr_item_sk AS item_sk,
           wr_reason_sk AS reason_sk,
           wr_net_loss AS net_loss,
           wr_return_quantity AS return_quantity,
           'web' AS return_channel
    FROM web_returns
)
SELECT i.i_item_id,
       i.i_product_name,
       r.r_reason_desc,
       t.t_hour,
       ur.return_channel,
       SUM(ur.net_loss) AS total_net_loss,
       SUM(ur.return_quantity) AS total_return_quantity,
       AVG(ur.net_loss) AS avg_net_loss_per_return
FROM unified_returns AS ur
JOIN item AS i
  ON ur.item_sk = i.i_item_sk
JOIN reason AS r
  ON ur.reason_sk = r.r_reason_sk
JOIN time_dim AS t
  ON ur.returned_time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 8 AND 20
GROUP BY i.i_item_id,
         i.i_product_name,
         r.r_reason_desc,
         t.t_hour,
         ur.return_channel
ORDER BY total_net_loss DESC
LIMIT 100
