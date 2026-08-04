WITH sampled_inventory AS (
        SELECT inv_date_sk, inv_item_sk, inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    full_date_inventory AS (
        SELECT
            d.d_date AS inv_date,
            i.i_item_id,
            COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand,
            CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 'No Inventory' ELSE 'Has Inventory' END AS inventory_status
        FROM date_dim d
        FULL OUTER JOIN sampled_inventory inv
            ON d.d_date_sk = inv.inv_date_sk
        LEFT JOIN item i
            ON inv.inv_item_sk = i.i_item_sk
    ),
    store_ret_agg AS (
        SELECT
            d.d_date AS return_date,
            i.i_item_id,
            SUM(sr.sr_return_quantity) AS total_return_qty,
            SUM(sr.sr_net_loss) AS total_net_loss,
            CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_date, i.i_item_id
    ),
    web_ret_agg AS (
        SELECT
            d.d_date AS return_date,
            i.i_item_id,
            SUM(wr.wr_return_quantity) AS total_return_qty,
            SUM(wr.wr_net_loss) AS total_net_loss,
            CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_date, i.i_item_id
    ),
    max_price_scalar AS (
        SELECT MAX(i_current_price) AS max_price FROM item
    )
SELECT
    c.return_date,
    c.i_item_id,
    c.total_return_qty,
    c.total_net_loss,
    c.loss_category,
    fdi.inventory_status,
    CASE
        WHEN c.total_net_loss > (SELECT max_price FROM max_price_scalar) THEN 'Above Max Price Loss'
        ELSE 'Below Max Price Loss'
    END AS loss_vs_max_price
FROM (
    SELECT return_date, i_item_id, total_return_qty, total_net_loss, loss_category
    FROM store_ret_agg
    UNION ALL
    SELECT return_date, i_item_id, total_return_qty, total_net_loss, loss_category
    FROM web_ret_agg
) c
LEFT JOIN full_date_inventory fdi
    ON c.return_date = fdi.inv_date
   AND c.i_item_id = fdi.i_item_id
WHERE c.i_item_id IS NOT NULL
ORDER BY c.return_date DESC, c.total_net_loss DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
