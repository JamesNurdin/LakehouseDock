WITH profit_loss_agg AS (
    -- Store sales profit
    SELECT
        i.i_category AS category,
        d.d_year   AS year,
        d.d_moy    AS month,
        SUM(ss.ss_net_profit) AS profit,
        0.0 AS loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy

    UNION ALL

    -- Catalog sales profit
    SELECT
        i.i_category AS category,
        d.d_year   AS year,
        d.d_moy    AS month,
        SUM(cs.cs_net_profit) AS profit,
        0.0 AS loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy

    UNION ALL

    -- Web sales profit
    SELECT
        i.i_category AS category,
        d.d_year   AS year,
        d.d_moy    AS month,
        SUM(ws.ws_net_profit) AS profit,
        0.0 AS loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy

    UNION ALL

    -- Store returns loss
    SELECT
        i.i_category AS category,
        d.d_year   AS year,
        d.d_moy    AS month,
        0.0 AS profit,
        SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy

    UNION ALL

    -- Catalog returns loss
    SELECT
        i.i_category AS category,
        d.d_year   AS year,
        d.d_moy    AS month,
        0.0 AS profit,
        SUM(cr.cr_net_loss) AS loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy

    UNION ALL

    -- Web returns loss
    SELECT
        i.i_category AS category,
        d.d_year   AS year,
        d.d_moy    AS month,
        0.0 AS profit,
        SUM(wr.wr_net_loss) AS loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy
),
combined AS (
    SELECT
        category,
        year,
        month,
        SUM(profit) AS total_profit,
        SUM(loss)   AS total_loss
    FROM profit_loss_agg
    GROUP BY category, year, month
),
inventory_agg AS (
    SELECT
        i.i_category AS category,
        d.d_year    AS year,
        d.d_moy     AS month,
        AVG(inv.inv_quantity_on_hand) AS avg_qty_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_category, d.d_year, d.d_moy
)
SELECT
    c.category,
    c.year,
    c.month,
    c.total_profit - c.total_loss AS net_profit_after_returns,
    COALESCE(i.avg_qty_on_hand, 0) AS avg_inventory_quantity
FROM combined c
LEFT JOIN inventory_agg i
    ON c.category = i.category
   AND c.year = i.year
   AND c.month = i.month
ORDER BY c.year, c.month, c.category
