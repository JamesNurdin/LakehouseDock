WITH inv_by_date_item AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS qty
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
),
open_qty AS (
    SELECT
        ws.web_site_sk,
        i.i_brand,
        COALESCE(SUM(iq.qty), 0) AS qty_on_open
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    JOIN inv_by_date_item iq ON iq.inv_date_sk = od.d_date_sk
    JOIN item i ON i.i_item_sk = iq.inv_item_sk
    GROUP BY ws.web_site_sk, i.i_brand
),
close_qty AS (
    SELECT
        ws.web_site_sk,
        i.i_brand,
        COALESCE(SUM(iq.qty), 0) AS qty_on_close
    FROM web_site ws
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
    JOIN inv_by_date_item iq ON iq.inv_date_sk = cd.d_date_sk
    JOIN item i ON i.i_item_sk = iq.inv_item_sk
    GROUP BY ws.web_site_sk, i.i_brand
),
brand_change AS (
    SELECT
        o.web_site_sk,
        o.i_brand,
        o.qty_on_open,
        COALESCE(c.qty_on_close, 0) AS qty_on_close,
        COALESCE(c.qty_on_close, 0) - o.qty_on_open AS qty_diff
    FROM open_qty o
    LEFT JOIN close_qty c
        ON o.web_site_sk = c.web_site_sk
       AND o.i_brand = c.i_brand
),
site_summary AS (
    SELECT
        bc.web_site_sk,
        SUM(bc.qty_diff) AS net_qty_diff
    FROM brand_change bc
    GROUP BY bc.web_site_sk
)
SELECT
    ws.web_site_id,
    ws.web_name,
    ss.net_qty_diff,
    CASE
        WHEN ss.net_qty_diff > 0 THEN 'Increase'
        WHEN ss.net_qty_diff < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS overall_trend,
    DENSE_RANK() OVER (ORDER BY ss.net_qty_diff DESC) AS site_rank
FROM site_summary ss
JOIN web_site ws ON ws.web_site_sk = ss.web_site_sk
ORDER BY site_rank
