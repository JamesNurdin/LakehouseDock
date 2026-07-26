WITH inv_on_open AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_on_open,
        SUM(i.i_current_price * inv.inv_quantity_on_hand) / NULLIF(SUM(inv.inv_quantity_on_hand), 0) AS avg_price_on_open
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = od.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY ws.web_site_sk
),
inv_on_close AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_on_close,
        SUM(i.i_current_price * inv.inv_quantity_on_hand) / NULLIF(SUM(inv.inv_quantity_on_hand), 0) AS avg_price_on_close
    FROM web_site ws
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = cd.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY ws.web_site_sk
),
site_combined AS (
    SELECT
        o.web_site_sk,
        o.qty_on_open,
        o.avg_price_on_open,
        COALESCE(c.qty_on_close, 0) AS qty_on_close,
        COALESCE(c.avg_price_on_close, 0) AS avg_price_on_close,
        CASE
            WHEN o.qty_on_open = 0 THEN NULL
            ELSE (c.qty_on_close - o.qty_on_open) * 100.0 / o.qty_on_open
        END AS pct_qty_change,
        CASE
            WHEN o.avg_price_on_open = 0 THEN NULL
            ELSE (c.avg_price_on_close - o.avg_price_on_open) * 100.0 / o.avg_price_on_open
        END AS pct_price_change
    FROM inv_on_open o
    LEFT JOIN inv_on_close c
        ON o.web_site_sk = c.web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_market_manager,
    sc.qty_on_open,
    sc.qty_on_close,
    ROUND(sc.pct_qty_change, 2) AS pct_qty_change,
    ROUND(sc.pct_price_change, 2) AS pct_price_change,
    CASE
        WHEN sc.pct_qty_change IS NULL THEN 'No Opening Inventory'
        WHEN sc.pct_qty_change > 50 THEN 'High Quantity Growth'
        WHEN sc.pct_qty_change > 0 THEN 'Moderate Quantity Growth'
        WHEN sc.pct_qty_change = 0 THEN 'Quantity No Change'
        ELSE 'Quantity Decline'
    END AS qty_growth_category,
    RANK() OVER (ORDER BY sc.pct_qty_change DESC NULLS LAST) AS qty_growth_rank
FROM site_combined sc
JOIN web_site ws ON ws.web_site_sk = sc.web_site_sk
ORDER BY qty_growth_rank
