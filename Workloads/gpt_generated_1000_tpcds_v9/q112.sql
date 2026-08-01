WITH store_ret AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        'store' AS return_source,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'high' ELSE 'low' END AS loss_level
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
    GROUP BY d.d_year, i.i_category
),
catalog_ret AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        'catalog' AS return_source,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'high' ELSE 'low' END AS loss_level
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory inv
        WHERE inv.inv_date_sk = d.d_date_sk
          AND inv.inv_item_sk = i.i_item_sk
          AND inv.inv_quantity_on_hand > 0
    )
    GROUP BY d.d_year, i.i_category
)
SELECT
    year,
    category,
    total_return_amount,
    return_source,
    loss_level
FROM store_ret
UNION ALL
SELECT
    year,
    category,
    total_return_amount,
    return_source,
    loss_level
FROM catalog_ret
ORDER BY year, total_return_amount DESC
LIMIT 100
