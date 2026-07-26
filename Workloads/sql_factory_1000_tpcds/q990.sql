WITH open_stats AS (
    SELECT
        ws.web_site_sk,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items_open,
        SUM(inv.inv_quantity_on_hand) AS qty_on_open
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    GROUP BY ws.web_site_sk
),
close_stats AS (
    SELECT
        ws.web_site_sk,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items_close,
        SUM(inv.inv_quantity_on_hand) AS qty_on_close
    FROM web_site ws
    JOIN date_dim d ON ws.web_close_date_sk = d.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    GROUP BY ws.web_site_sk
),
merged AS (
    SELECT
        o.web_site_sk,
        o.distinct_items_open,
        o.qty_on_open,
        COALESCE(c.distinct_items_close,0) AS distinct_items_close,
        COALESCE(c.qty_on_close,0) AS qty_on_close,
        (COALESCE(c.qty_on_close,0) - o.qty_on_open) AS qty_change,
        (COALESCE(c.distinct_items_close,0) - o.distinct_items_open) AS item_change
    FROM open_stats o
    LEFT JOIN close_stats c ON o.web_site_sk = c.web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_market_manager,
    m.distinct_items_open,
    m.distinct_items_close,
    m.qty_change,
    m.item_change,
    CASE WHEN m.item_change > 0 THEN 'More Items' WHEN m.item_change = 0 THEN 'Same Items' ELSE 'Fewer Items' END AS item_change_category,
    RANK() OVER (ORDER BY m.qty_change DESC) AS qty_change_rank
FROM merged m
JOIN web_site ws ON ws.web_site_sk = m.web_site_sk
WHERE m.qty_on_open > 0
ORDER BY qty_change_rank
