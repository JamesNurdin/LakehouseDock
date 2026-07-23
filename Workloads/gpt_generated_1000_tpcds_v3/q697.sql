WITH unified_returns AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        cr.cr_net_loss AS net_loss,
        cr.cr_refunded_hdemo_sk AS hdemo_sk,
        cr.cr_returned_date_sk AS returned_date_sk,
        i.i_category AS category
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{2}[A-Z]{3}')
      AND i.i_category LIKE 'A%'
    UNION ALL
    SELECT
        wr.wr_item_sk AS item_sk,
        NULL AS warehouse_sk,
        wr.wr_net_loss AS net_loss,
        wr.wr_refunded_hdemo_sk AS hdemo_sk,
        wr.wr_returned_date_sk AS returned_date_sk,
        i.i_category AS category
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{2}[A-Z]{3}')
      AND i.i_category LIKE 'A%'
)
SELECT
    COALESCE(w.w_warehouse_name, 'WEB_RETURN') AS warehouse_name,
    ur.category,
    SUM(ur.net_loss) AS total_net_loss,
    COUNT(DISTINCT ur.item_sk) AS distinct_items,
    (
        SELECT SUM(inv.inv_quantity_on_hand)
        FROM inventory inv
        JOIN item i2 ON inv.inv_item_sk = i2.i_item_sk
        WHERE i2.i_category = ur.category
    ) AS total_inventory_qty
FROM unified_returns ur
LEFT JOIN warehouse w
    ON ur.warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON ur.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound BETWEEN 20000 AND 50000
GROUP BY COALESCE(w.w_warehouse_name, 'WEB_RETURN'), ur.category
ORDER BY total_net_loss DESC
LIMIT 50
