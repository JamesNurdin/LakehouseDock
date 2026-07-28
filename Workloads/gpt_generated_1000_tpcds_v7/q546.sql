WITH joined_data AS (
    SELECT
        i.i_category AS category,
        i.i_product_name AS product_name,
        i.i_container AS container,
        t.t_sub_shift AS sub_shift,
        inv.inv_warehouse_sk AS warehouse_sk,
        inv.inv_quantity_on_hand AS qty_on_hand,
        sr.sr_return_amt AS store_return_amt,
        sr.sr_net_loss AS store_net_loss,
        wr.wr_return_amt AS web_return_amt,
        wr.wr_net_loss AS web_net_loss
    FROM inventory inv
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE
        t.t_time IN (8, 14, 13)                     -- filter on specific hours
        AND t.t_sub_shift = 'morning'               -- filter on sub‑shift
        AND i.i_category = 'Books'                  -- focus on a product category
        AND inv.inv_warehouse_sk IN (8, 13)          -- specific warehouses
        AND inv.inv_quantity_on_hand > 100          -- inventory threshold
),
aggregated AS (
    SELECT
        category,
        sub_shift,
        (store_return_amt + web_return_amt) AS total_return_amt,
        (store_net_loss + web_net_loss) AS total_net_loss
    FROM joined_data
)
SELECT
    category,
    sub_shift,
    SUM(total_return_amt) AS total_return_amount,
    AVG(total_net_loss) AS avg_net_loss,
    COUNT(*) AS record_count
FROM aggregated
GROUP BY category, sub_shift
HAVING SUM(total_return_amt) > 1000                -- keep only high‑volume groups
ORDER BY avg_net_loss DESC
LIMIT 10
