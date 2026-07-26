WITH inv_on_open AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_on_open,
        SUM(i.i_current_price * inv.inv_quantity_on_hand) AS total_value_on_open
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = od.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    WHERE ws.web_state = 'CA'
    GROUP BY ws.web_site_sk
),
inv_on_close AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_on_close,
        SUM(i.i_current_price * inv.inv_quantity_on_hand) AS total_value_on_close
    FROM web_site ws
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = cd.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    WHERE ws.web_state = 'CA'
    GROUP BY ws.web_site_sk
),
site_combined AS (
    SELECT
        o.web_site_sk,
        o.qty_on_open,
        o.total_value_on_open,
        COALESCE(c.qty_on_close, 0) AS qty_on_close,
        COALESCE(c.total_value_on_close, 0) AS total_value_on_close,
        (c.total_value_on_close - o.total_value_on_open) / NULLIF(o.total_value_on_open, 0) * 100 AS pct_value_change
    FROM inv_on_open o
    LEFT JOIN inv_on_close c ON o.web_site_sk = c.web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    sc.qty_on_open,
    sc.qty_on_close,
    ROUND(sc.pct_value_change, 2) AS pct_value_change,
    NTILE(4) OVER (ORDER BY sc.pct_value_change DESC) AS quartile_rank,
    CASE
        WHEN sc.pct_value_change IS NULL THEN 'No Data'
        WHEN sc.pct_value_change > 20 THEN 'Strong Increase'
        WHEN sc.pct_value_change > 0 THEN 'Moderate Increase'
        ELSE 'Decrease'
    END AS value_trend
FROM site_combined sc
JOIN web_site ws ON ws.web_site_sk = sc.web_site_sk
WHERE sc.qty_on_open > 0
ORDER BY pct_value_change DESC
