WITH catalog_sales_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        sm.sm_ship_mode_id AS ship_mode,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2002-01-01'
      AND d.d_date < DATE '2003-01-01'
),
web_sales_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        sm.sm_ship_mode_id AS ship_mode,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2002-01-01'
      AND d.d_date < DATE '2003-01-01'
),
catalog_returns_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category AS category,
        sm.sm_ship_mode_id AS ship_mode,
        -cr.cr_net_loss AS net_profit
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2002-01-01'
      AND d.d_date < DATE '2003-01-01'
)
SELECT
    year,
    month,
    category,
    ship_mode,
    sum(net_profit) AS total_net_profit
FROM (
    SELECT year, month, category, ship_mode, net_profit FROM catalog_sales_monthly
    UNION ALL
    SELECT year, month, category, ship_mode, net_profit FROM web_sales_monthly
    UNION ALL
    SELECT year, month, category, ship_mode, net_profit FROM catalog_returns_monthly
) combined
GROUP BY year, month, category, ship_mode
ORDER BY year, month, category, total_net_profit DESC
