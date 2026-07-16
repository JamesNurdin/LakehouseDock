SELECT
    inv_warehouse_sk,
    inv_item_sk,
    inv_date_sk,
    total_inventory_qty,
    total_return_qty,
    total_return_amt,
    total_net_loss,
    avg_return_amt_per_qty,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_date_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        SUM(w.wr_return_quantity) AS total_return_qty,
        SUM(w.wr_return_amt) AS total_return_amt,
        SUM(w.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(w.wr_return_quantity) = 0 THEN 0
             ELSE SUM(w.wr_return_amt) / SUM(w.wr_return_quantity) END AS avg_return_amt_per_qty
    FROM inventory i
    JOIN web_returns w
      ON i.inv_item_sk = w.wr_item_sk
     AND i.inv_date_sk = w.wr_returned_date_sk
    WHERE i.inv_quantity_on_hand > 200
      AND w.wr_return_amt > 0
    GROUP BY i.inv_warehouse_sk, i.inv_item_sk, i.inv_date_sk
) t
ORDER BY total_net_loss DESC
LIMIT 100
