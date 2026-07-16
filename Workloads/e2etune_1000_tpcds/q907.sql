SELECT
    t.cr_item_sk,
    t.cr_warehouse_sk,
    t.inv_quantity_on_hand,
    t.total_return_qty,
    t.total_return_amount,
    t.total_net_loss,
    t.avg_return_amount,
    t.return_qty_ratio,
    RANK() OVER (ORDER BY t.total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        i.inv_quantity_on_hand,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_return_quantity) * 1.0 / NULLIF(i.inv_quantity_on_hand, 0) AS return_qty_ratio
    FROM catalog_returns cr
    JOIN inventory i
        ON cr.cr_item_sk = i.inv_item_sk
        AND cr.cr_warehouse_sk = i.inv_warehouse_sk
        AND cr.cr_returned_date_sk = i.inv_date_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity > 0
    GROUP BY cr.cr_item_sk, cr.cr_warehouse_sk, i.inv_quantity_on_hand
    HAVING SUM(cr.cr_return_quantity) > 10
) t
ORDER BY t.total_net_loss DESC
LIMIT 100
