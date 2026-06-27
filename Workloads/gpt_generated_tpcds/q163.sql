WITH combined AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        sm.sm_type AS ship_mode,
        cs.cs_net_profit AS amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sm.sm_type,
        ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        sm.sm_type,
        -cr.cr_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
)
SELECT
    year,
    month,
    category,
    ship_mode,
    SUM(amount) AS net_profit
FROM combined
GROUP BY year, month, category, ship_mode
ORDER BY year, month, category, ship_mode
