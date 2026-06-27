WITH sales AS (
    -- Combine catalog and web sales for the target year
    SELECT
        i.i_category,
        d.d_year AS year,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001

    UNION ALL

    SELECT
        i.i_category,
        d.d_year AS year,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
),

sales_agg AS (
    SELECT
        i_category,
        year,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY i_category, year
),

returns AS (
    SELECT
        i.i_category,
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year
),

inventory_agg AS (
    SELECT
        i.i_category,
        d.d_year AS year,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category, d.d_year
)
SELECT
    sa.i_category,
    sa.year,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.total_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(i.avg_inventory_qty, 0) AS avg_inventory_qty,
    (sa.total_net_profit - COALESCE(r.total_return_amount, 0)) / NULLIF(COALESCE(i.avg_inventory_qty, 0), 0) AS profit_per_inventory
FROM sales_agg sa
LEFT JOIN returns r
    ON sa.i_category = r.i_category
    AND sa.year = r.year
LEFT JOIN inventory_agg i
    ON sa.i_category = i.i_category
    AND sa.year = i.year
ORDER BY profit_per_inventory DESC
LIMIT 10
