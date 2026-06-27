WITH sales AS (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_warehouse_sk AS warehouse_sk,
           cs.cs_net_profit AS net_profit,
           cs.cs_net_paid AS net_paid
    FROM catalog_sales cs
    UNION ALL
    SELECT ws.ws_item_sk AS item_sk,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_warehouse_sk AS warehouse_sk,
           ws.ws_net_profit AS net_profit,
           ws.ws_net_paid AS net_paid
    FROM web_sales ws
),

sales_filtered AS (
    SELECT s.item_sk,
           s.date_sk,
           s.net_profit,
           s.net_paid
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),

sales_agg AS (
    SELECT i.i_category,
           d.d_year,
           d.d_moy AS month,
           SUM(s.net_profit) AS total_net_profit,
           SUM(s.net_paid) AS total_net_paid
    FROM sales_filtered s
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    GROUP BY i.i_category, d.d_year, d.d_moy
),

returns_agg AS (
    SELECT i.i_category,
           d.d_year,
           d.d_moy AS month,
           SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_category, d.d_year, d.d_moy
),

inventory_agg AS (
    SELECT i.i_category,
           d.d_year,
           d.d_moy AS month,
           AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY i.i_category, d.d_year, d.d_moy
)

SELECT
    sa.i_category,
    sa.d_year,
    sa.month,
    sa.total_net_profit,
    COALESCE(ra.total_net_loss, 0) AS total_net_loss,
    sa.total_net_profit - COALESCE(ra.total_net_loss, 0) AS net_margin,
    sa.total_net_paid,
    COALESCE(ia.avg_qty_on_hand, 0) AS avg_qty_on_hand
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.i_category = ra.i_category
   AND sa.d_year = ra.d_year
   AND sa.month = ra.month
LEFT JOIN inventory_agg ia
    ON sa.i_category = ia.i_category
   AND sa.d_year = ia.d_year
   AND sa.month = ia.month
ORDER BY net_margin DESC
LIMIT 100
