WITH agg AS (
    SELECT
        w.w_warehouse_name,
        it.i_brand,
        COALESCE(r.r_reason_desc, 'No Return') AS reason_desc,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_return_qty,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_net_loss,
        AVG(it.i_current_price) AS avg_item_price
    FROM inventory i
    JOIN item it
        ON i.inv_item_sk = it.i_item_sk
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = it.i_item_sk
        AND sr.sr_returned_date_sk BETWEEN 2450800 AND 2451200
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i.inv_quantity_on_hand > 500
      AND it.i_current_price > 20
    GROUP BY w.w_warehouse_name, it.i_brand, r.r_reason_desc
    HAVING SUM(COALESCE(sr.sr_net_loss, 0)) > 0
)
SELECT
    agg.w_warehouse_name,
    agg.i_brand,
    agg.reason_desc,
    agg.total_inventory_qty,
    agg.total_return_qty,
    agg.total_net_loss,
    agg.avg_item_price,
    ROW_NUMBER() OVER (PARTITION BY agg.w_warehouse_name ORDER BY agg.total_net_loss DESC) AS loss_reason_rank
FROM agg
ORDER BY agg.w_warehouse_name, agg.total_net_loss DESC
LIMIT 30
