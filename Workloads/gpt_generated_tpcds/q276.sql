WITH
    c_sales AS (
        SELECT
            i.i_category AS i_category,
            d.d_year AS d_year,
            d.d_moy AS d_moy,
            SUM(cs.cs_net_profit) AS catalog_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    w_sales AS (
        SELECT
            i.i_category AS i_category,
            d.d_year AS d_year,
            d.d_moy AS d_moy,
            SUM(ws.ws_net_profit) AS web_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    c_returns AS (
        SELECT
            i.i_category AS i_category,
            d.d_year AS d_year,
            d.d_moy AS d_moy,
            SUM(cr.cr_net_loss) AS returns_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    inventory_agg AS (
        SELECT
            i.i_category AS i_category,
            d.d_year AS d_year,
            d.d_moy AS d_moy,
            AVG(inv.inv_quantity_on_hand) AS avg_inventory
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        GROUP BY i.i_category, d.d_year, d.d_moy
    ),
    base_month_category AS (
        SELECT i_category, d_year, d_moy FROM c_sales
        UNION
        SELECT i_category, d_year, d_moy FROM w_sales
        UNION
        SELECT i_category, d_year, d_moy FROM c_returns
        UNION
        SELECT i_category, d_year, d_moy FROM inventory_agg
    )
SELECT
    base.i_category,
    base.d_year,
    base.d_moy,
    COALESCE(cs.catalog_profit, 0) AS catalog_profit,
    COALESCE(ws.web_profit, 0) AS web_profit,
    COALESCE(cr.returns_loss, 0) AS returns_loss,
    COALESCE(inv.avg_inventory, 0) AS avg_inventory,
    COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) - COALESCE(cr.returns_loss, 0) AS total_net_profit,
    SUM(COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) - COALESCE(cr.returns_loss, 0))
        OVER (PARTITION BY base.i_category ORDER BY base.d_year, base.d_moy ROWS UNBOUNDED PRECEDING) AS running_total_net_profit
FROM base_month_category base
LEFT JOIN c_sales cs
    ON base.i_category = cs.i_category
    AND base.d_year = cs.d_year
    AND base.d_moy = cs.d_moy
LEFT JOIN w_sales ws
    ON base.i_category = ws.i_category
    AND base.d_year = ws.d_year
    AND base.d_moy = ws.d_moy
LEFT JOIN c_returns cr
    ON base.i_category = cr.i_category
    AND base.d_year = cr.d_year
    AND base.d_moy = cr.d_moy
LEFT JOIN inventory_agg inv
    ON base.i_category = inv.i_category
    AND base.d_year = inv.d_year
    AND base.d_moy = inv.d_moy
ORDER BY base.d_year, base.d_moy, base.i_category
