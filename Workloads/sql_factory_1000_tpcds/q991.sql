WITH open_inventory AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_open,
        SUM(i.i_current_price * inv.inv_quantity_on_hand) AS total_value_open
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY ws.web_site_sk
),
close_inventory AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_close,
        SUM(i.i_current_price * inv.inv_quantity_on_hand) AS total_value_close
    FROM web_site ws
    JOIN date_dim d ON ws.web_close_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    GROUP BY ws.web_site_sk
),
combined AS (
    SELECT
        o.web_site_sk,
        o.total_qty_open,
        o.total_value_open / NULLIF(o.total_qty_open,0) AS avg_price_open,
        COALESCE(c.total_qty_close,0) AS total_qty_close,
        COALESCE(c.total_value_close,0) / NULLIF(COALESCE(c.total_qty_close,0),0) AS avg_price_close,
        (COALESCE(c.total_qty_close,0) - o.total_qty_open) AS qty_diff,
        (COALESCE(c.total_value_close,0) - o.total_value_open) AS value_diff
    FROM open_inventory o
    LEFT JOIN close_inventory c ON o.web_site_sk = c.web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_market_manager,
    c.total_qty_open,
    c.total_qty_close,
    c.avg_price_open,
    c.avg_price_close,
    c.qty_diff,
    c.value_diff,
    NTILE(4) OVER (ORDER BY c.qty_diff DESC) AS qty_quartile
FROM combined c
JOIN web_site ws ON ws.web_site_sk = c.web_site_sk
WHERE c.total_qty_open > 0
ORDER BY qty_quartile, c.qty_diff DESC
