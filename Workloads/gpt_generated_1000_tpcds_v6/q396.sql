WITH distinct_items AS (
    SELECT DISTINCT i_item_id, i_item_sk
    FROM item
    WHERE i_brand_id IN (1, 2, 3)
      AND i_category = 'Sports'
      AND i_color = 'BLACK'
),

inventory_metrics AS (
    SELECT di.i_item_id,
           wh.w_warehouse_name,
           SUM(inv.inv_quantity_on_hand) AS metric_value,
           'inventory_qty' AS metric_type
    FROM inventory inv
    JOIN distinct_items di ON inv.inv_item_sk = di.i_item_sk
    JOIN warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    WHERE inv.inv_date_sk BETWEEN 2450800 AND 2451100
      AND wh.w_warehouse_sq_ft > 500000
    GROUP BY di.i_item_id, wh.w_warehouse_name
),

return_metrics AS (
    SELECT di.i_item_id,
           NULL AS w_warehouse_name,
           SUM(wr.wr_net_loss) AS metric_value,
           'return_loss' AS metric_type
    FROM web_returns wr
    JOIN distinct_items di ON wr.wr_item_sk = di.i_item_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450800 AND 2451100
      AND wr.wr_refunded_customer_sk IN (6302889, 10455891)
      AND wr.wr_refunded_hdemo_sk IN (6530, 5522)
      AND wr.wr_return_quantity > 0
    GROUP BY di.i_item_id
),

combined AS (
    SELECT i_item_id, w_warehouse_name, metric_type, metric_value
    FROM inventory_metrics
    UNION ALL
    SELECT i_item_id, w_warehouse_name, metric_type, metric_value
    FROM return_metrics
)
SELECT
    c.i_item_id,
    c.w_warehouse_name,
    c.metric_type,
    c.metric_value,
    ROW_NUMBER() OVER (PARTITION BY c.metric_type ORDER BY c.metric_value DESC) AS rank
FROM combined c
ORDER BY c.metric_type, rank
LIMIT 100
