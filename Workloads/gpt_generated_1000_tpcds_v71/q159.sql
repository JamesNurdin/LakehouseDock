WITH returns_items AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        i.i_item_sk,
        i.i_item_id,
        i.i_class_id,
        i.i_category,
        t.t_time_id,
        t.t_second
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE i.i_class_id IN (10, 13, 15)
      AND i.i_rec_end_date > DATE '2000-01-01'
      AND t.t_second BETWEEN 5 AND 15
      AND cr.cr_return_amount > 50
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS ws_total_sales,
        AVG(ws.ws_sales_price) AS ws_avg_price
    FROM web_sales ws
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    WHERE ws.ws_wholesale_cost BETWEEN 30 AND 90
      AND i2.i_manager_id IN (21, 44)
    GROUP BY ws.ws_item_sk, ws.ws_order_number
)
SELECT
    ri.cr_order_number,
    ri.i_item_id,
    ri.i_class_id,
    ri.i_category,
    ri.cr_return_quantity,
    ri.cr_return_amount,
    ri.cr_net_loss,
    ri.t_time_id,
    CASE
        WHEN ri.cr_net_loss > 100 THEN 'High'
        WHEN ri.cr_net_loss > 50 THEN 'Medium'
        ELSE 'Low'
    END AS loss_severity,
    wa.ws_total_sales,
    wa.ws_avg_price,
    RANK() OVER (PARTITION BY ri.i_class_id ORDER BY ri.cr_net_loss DESC) AS net_loss_rank,
    ROW_NUMBER() OVER (PARTITION BY ri.i_class_id ORDER BY ri.cr_return_amount DESC) AS amt_row_num
FROM returns_items ri
LEFT JOIN ws_agg wa ON ri.i_item_sk = wa.ws_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_sales ws2
    WHERE ws2.ws_order_number = ri.cr_order_number
      AND ws2.ws_item_sk = ri.i_item_sk
)
ORDER BY ri.i_class_id, net_loss_rank
LIMIT 100
