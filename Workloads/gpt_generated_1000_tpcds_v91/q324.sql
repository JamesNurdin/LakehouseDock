WITH agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        AVG(i.i_wholesale_cost) AS avg_wholesale_cost,
        MAX(inv.inv_quantity_on_hand) AS max_inventory_on_hand,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_wholesale_cost > 5.00
      AND i.i_units = 'Ounce'
      AND inv.inv_quantity_on_hand >= 800
      AND cr.cr_return_tax > 20.00
      AND cr.cr_refunded_customer_sk IN (6784621, 7942409)
      AND EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_quantity_on_hand > 900
      )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, w.w_warehouse_name
)
SELECT
    agg.i_item_id,
    agg.i_product_name,
    agg.w_warehouse_name,
    agg.total_return_amount,
    agg.total_web_return_amount,
    (agg.total_catalog_return_qty + agg.total_web_return_qty) AS total_return_quantity,
    agg.avg_wholesale_cost,
    agg.max_inventory_on_hand,
    agg.catalog_order_cnt,
    agg.web_order_cnt,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = agg.i_item_sk
    ) AS avg_return_amount_all_items,
    RANK() OVER (ORDER BY agg.total_return_amount DESC) AS return_amount_rank,
    SUM(agg.total_return_amount) OVER (
        ORDER BY agg.total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
