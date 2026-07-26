WITH inv_on_open AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_on_open,
        AVG(i.i_current_price) AS avg_price_on_open
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = od.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    WHERE od.d_year = 2001
    GROUP BY ws.web_site_sk
),
inv_on_close AS (
    SELECT
        ws.web_site_sk,
        SUM(inv.inv_quantity_on_hand) AS qty_on_close,
        AVG(i.i_current_price) AS avg_price_on_close
    FROM web_site ws
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
    JOIN inventory inv ON inv.inv_date_sk = cd.d_date_sk
    JOIN item i ON i.i_item_sk = inv.inv_item_sk
    WHERE cd.d_year = 2001
    GROUP BY ws.web_site_sk
),
site_combined AS (
    SELECT
        o.web_site_sk,
        o.qty_on_open,
        o.avg_price_on_open,
        COALESCE(c.qty_on_close, 0) AS qty_on_close,
        COALESCE(c.avg_price_on_close, 0) AS avg_price_on_close,
        (c.qty_on_close - o.qty_on_open) AS qty_diff,
        (c.avg_price_on_close - o.avg_price_on_open) AS price_diff
    FROM inv_on_open o
    LEFT JOIN inv_on_close c ON o.web_site_sk = c.web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    ws.web_market_manager,
    sc.qty_on_open,
    sc.qty_on_close,
    sc.qty_diff,
    sc.price_diff,
    CASE
        WHEN sc.qty_diff > 1000 THEN 'Huge Growth'
        WHEN sc.qty_diff > 0 THEN 'Positive Growth'
        WHEN sc.qty_diff = 0 THEN 'No Change'
        ELSE 'Negative Growth'
    END AS growth_category,
    ROW_NUMBER() OVER (ORDER BY sc.price_diff DESC) AS price_change_rank
FROM site_combined sc
JOIN web_site ws ON ws.web_site_sk = sc.web_site_sk
ORDER BY price_change_rank
