WITH inv_on_open AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_on_open,
        SUM(i.i_current_price * inv.inv_quantity_on_hand) AS value_on_open,
        MIN(od.d_date) AS open_date
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
        SUM(i.i_current_price * inv.inv_quantity_on_hand) AS value_on_close,
        MAX(cd.d_date) AS close_date
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
        o.value_on_open,
        COALESCE(c.qty_on_close, 0) AS qty_on_close,
        COALESCE(c.value_on_close, 0) AS value_on_close,
        o.open_date,
        c.close_date,
        (c.value_on_close - o.value_on_open) / NULLIF(o.value_on_open, 0) * 100 AS pct_value_change,
        ROW_NUMBER() OVER (PARTITION BY ws.web_market_manager ORDER BY (c.value_on_close - o.value_on_open) DESC) AS mgr_value_rank
    FROM inv_on_open o
    LEFT JOIN inv_on_close c ON o.web_site_sk = c.web_site_sk
    JOIN web_site ws ON ws.web_site_sk = o.web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_market_manager,
    sc.qty_on_open,
    sc.qty_on_close,
    ROUND(sc.pct_value_change, 2) AS pct_value_change,
    sc.mgr_value_rank,
    CASE
        WHEN sc.pct_value_change IS NULL THEN 'No Change Data'
        WHEN sc.pct_value_change > 10 THEN 'Value Increase'
        WHEN sc.pct_value_change < -10 THEN 'Value Decrease'
        ELSE 'Value Stable'
    END AS value_trend
FROM site_combined sc
JOIN web_site ws ON ws.web_site_sk = sc.web_site_sk
WHERE sc.qty_on_open > 0
ORDER BY sc.mgr_value_rank
