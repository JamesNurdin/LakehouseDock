WITH inv_on_open AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) FILTER (WHERE i.i_category = 'Electronics') AS electronics_qty_open,
        SUM(inv.inv_quantity_on_hand) FILTER (WHERE i.i_category <> 'Electronics') AS other_qty_open
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = od.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY ws.web_site_sk
),
inv_on_close AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) FILTER (WHERE i.i_category = 'Electronics') AS electronics_qty_close,
        SUM(inv.inv_quantity_on_hand) FILTER (WHERE i.i_category <> 'Electronics') AS other_qty_close
    FROM web_site ws
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = cd.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY ws.web_site_sk
),
site_combined AS (
    SELECT
        o.web_site_sk,
        o.electronics_qty_open,
        o.other_qty_open,
        COALESCE(c.electronics_qty_close, 0) AS electronics_qty_close,
        COALESCE(c.other_qty_close, 0) AS other_qty_close,
        (c.electronics_qty_close - o.electronics_qty_open) * 100.0 / NULLIF(o.electronics_qty_open, 0) AS pct_elec_change,
        (c.other_qty_close - o.other_qty_open) * 100.0 / NULLIF(o.other_qty_open, 0) AS pct_other_change
    FROM inv_on_open o
    LEFT JOIN inv_on_close c ON o.web_site_sk = c.web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    sc.electronics_qty_open,
    sc.electronics_qty_close,
    ROUND(sc.pct_elec_change, 2) AS pct_elec_change,
    sc.other_qty_open,
    sc.other_qty_close,
    ROUND(sc.pct_other_change, 2) AS pct_other_change,
    CASE
        WHEN sc.pct_elec_change > 30 THEN 'Electronics Surge'
        WHEN sc.pct_elec_change < -30 THEN 'Electronics Drop'
        ELSE 'Electronics Stable'
    END AS elec_trend,
    RANK() OVER (ORDER BY sc.pct_other_change DESC) AS other_change_rank
FROM site_combined sc
JOIN web_site ws ON ws.web_site_sk = sc.web_site_sk
WHERE sc.electronics_qty_open + sc.other_qty_open > 0
ORDER BY other_change_rank
