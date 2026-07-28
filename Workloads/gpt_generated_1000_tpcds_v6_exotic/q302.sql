WITH filtered_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 20
)
SELECT
    item_sk,
    order_number,
    net_paid,
    return_amount,
    ROW_NUMBER() OVER (PARTITION BY item_sk ORDER BY net_paid DESC) AS rn
FROM (
    SELECT
        fs.cs_item_sk AS item_sk,
        fs.cs_order_number AS order_number,
        fs.cs_net_paid_inc_ship_tax AS net_paid,
        cr.cr_return_amount AS return_amount
    FROM filtered_sales fs
    JOIN catalog_returns cr
        ON fs.cs_item_sk = cr.cr_item_sk
        AND fs.cs_order_number = cr.cr_order_number
    WHERE cr.cr_return_amount > 1000

    UNION ALL

    SELECT
        fs.cs_item_sk AS item_sk,
        fs.cs_order_number AS order_number,
        fs.cs_net_paid_inc_ship_tax AS net_paid,
        CAST(0 AS decimal(7,2)) AS return_amount
    FROM filtered_sales fs
    LEFT JOIN catalog_returns cr
        ON fs.cs_item_sk = cr.cr_item_sk
        AND fs.cs_order_number = cr.cr_order_number
    WHERE cr.cr_return_amount IS NULL
      AND fs.cs_net_paid_inc_ship_tax > 4000
) AS combined
ORDER BY net_paid DESC, rn
LIMIT 100
