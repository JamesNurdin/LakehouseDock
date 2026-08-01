WITH filtered_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    item_id,
    transaction_date,
    amount,
    transaction_type,
    total_inventory
FROM (
    SELECT
        i.i_item_id AS item_id,
        fd.d_date AS transaction_date,
        SUM(ss.ss_ext_sales_price) AS amount,
        'sale' AS transaction_type,
        inv_lateral.total_inventory
    FROM store_sales ss
    JOIN filtered_dates fd ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT COALESCE(SUM(inv_quantity_on_hand), 0) AS total_inventory
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_date_sk = fd.d_date_sk
    ) AS inv_lateral
    GROUP BY i.i_item_id, fd.d_date, inv_lateral.total_inventory
    UNION ALL
    SELECT
        i.i_item_id AS item_id,
        fd.d_date AS transaction_date,
        SUM(cr.cr_return_amount) AS amount,
        'return' AS transaction_type,
        inv_lateral.total_inventory
    FROM catalog_returns cr
    JOIN filtered_dates fd ON cr.cr_returned_date_sk = fd.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT COALESCE(SUM(inv_quantity_on_hand), 0) AS total_inventory
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
          AND inv.inv_date_sk = fd.d_date_sk
    ) AS inv_lateral
    GROUP BY i.i_item_id, fd.d_date, inv_lateral.total_inventory
) combined
ORDER BY amount DESC
LIMIT 100
