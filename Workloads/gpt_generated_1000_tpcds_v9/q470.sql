WITH item_return_union AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           SUM(sr.sr_return_quantity) AS return_qty,
           SUM(sr.sr_net_loss) AS net_loss,
           'store' AS source
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 18
    GROUP BY i.i_item_sk, i.i_item_id
    UNION ALL
    SELECT i.i_item_sk,
           i.i_item_id,
           SUM(wr.wr_return_quantity) AS return_qty,
           SUM(wr.wr_net_loss) AS net_loss,
           'web' AS source
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 18
    GROUP BY i.i_item_sk, i.i_item_id
)
SELECT ir.i_item_id,
       ir.i_item_sk,
       ir.source,
       ir.return_qty,
       ir.net_loss
FROM item_return_union ir
WHERE ir.net_loss > (SELECT AVG(cr.cr_net_loss) FROM catalog_returns cr)
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN item i2 ON cr2.cr_item_sk = i2.i_item_sk
        WHERE i2.i_item_sk = ir.i_item_sk
          AND cr2.cr_net_loss > (SELECT AVG(cr3.cr_net_loss) FROM catalog_returns cr3)
      )
ORDER BY ir.net_loss DESC
LIMIT 100
