WITH catalog_ret AS (
    SELECT
        'catalog' AS return_source,
        cr.cr_order_number AS order_number,
        d.d_date AS return_date,
        r.r_reason_desc AS reason,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 0
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = cr.cr_item_sk
            AND inv.inv_date_sk = cr.cr_returned_date_sk
      )
),
web_ret AS (
    SELECT
        'web' AS return_source,
        wr.wr_order_number AS order_number,
        d.d_date AS return_date,
        r.r_reason_desc AS reason,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt > 0
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = wr.wr_item_sk
            AND inv.inv_date_sk = wr.wr_returned_date_sk
      )
)
SELECT return_source,
       order_number,
       return_date,
       reason,
       return_amount,
       net_loss
FROM catalog_ret
UNION ALL
SELECT return_source,
       order_number,
       return_date,
       reason,
       return_amount,
       net_loss
FROM web_ret
ORDER BY return_date DESC,
         return_amount DESC
LIMIT 100
