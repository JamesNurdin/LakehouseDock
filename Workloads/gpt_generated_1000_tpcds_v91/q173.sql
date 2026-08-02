WITH
    no_store_return_items AS (
        SELECT DISTINCT i.i_item_sk,
            i.i_category,
            i.i_class,
            i.i_product_name
        FROM item i
        WHERE NOT EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_item_sk = i.i_item_sk
        )
    ),
    web_agg AS (
        SELECT
            n.i_item_sk,
            n.i_category,
            n.i_class,
            n.i_product_name,
            'web' AS channel,
            SUM(ws.ws_net_paid) AS total_net_paid,
            SUM(ws.ws_net_profit) AS total_net_profit,
            SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
        FROM web_sales ws
        JOIN no_store_return_items n ON ws.ws_item_sk = n.i_item_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        WHERE d.d_year = 2022
        GROUP BY n.i_item_sk, n.i_category, n.i_class, n.i_product_name
    ),
    catalog_agg AS (
        SELECT
            n.i_item_sk,
            n.i_category,
            n.i_class,
            n.i_product_name,
            'catalog' AS channel,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_net_profit,
            SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss
        FROM catalog_sales cs
        JOIN no_store_return_items n ON cs.cs_item_sk = n.i_item_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        WHERE d.d_year = 2022
        GROUP BY n.i_item_sk, n.i_category, n.i_class, n.i_product_name
    ),
    union_all_data AS (
        SELECT
            i_item_sk,
            i_category,
            i_class,
            i_product_name,
            channel,
            total_net_paid,
            total_net_profit,
            total_return_loss,
            (SELECT COALESCE(SUM(inv_quantity_on_hand), 0)
             FROM inventory inv
             JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
             WHERE inv.inv_item_sk = i_item_sk
               AND d2.d_date = DATE '2023-12-31') AS inventory_qty_on_date
        FROM web_agg
        UNION ALL
        SELECT
            i_item_sk,
            i_category,
            i_class,
            i_product_name,
            channel,
            total_net_paid,
            total_net_profit,
            total_return_loss,
            (SELECT COALESCE(SUM(inv_quantity_on_hand), 0)
             FROM inventory inv
             JOIN date_dim d2 ON inv.inv_date_sk = d2.d_date_sk
             WHERE inv.inv_item_sk = i_item_sk
               AND d2.d_date = DATE '2023-12-31') AS inventory_qty_on_date
        FROM catalog_agg
    )
SELECT
    i_category,
    i_class,
    i_product_name,
    channel,
    SUM(total_net_paid) AS sum_net_paid,
    SUM(total_net_profit) AS sum_net_profit,
    SUM(total_return_loss) AS sum_return_loss,
    MAX(inventory_qty_on_date) AS inventory_on_2023_12_31
FROM union_all_data
GROUP BY ROLLUP (i_category, i_class, i_product_name, channel)
HAVING SUM(total_net_paid) > 0
ORDER BY i_category, i_class, i_product_name, channel
LIMIT 100
