WITH store_item AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
),
web_item AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_return_quantity) AS web_return_qty,
        SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
combined_items AS (
    SELECT
        COALESCE(s.item_sk, w.item_sk) AS item_sk,
        COALESCE(s.store_return_qty, 0) AS store_return_qty,
        COALESCE(w.web_return_qty, 0) AS web_return_qty,
        COALESCE(s.store_net_loss, 0) AS store_net_loss,
        COALESCE(w.web_net_loss, 0) AS web_net_loss,
        COALESCE(s.store_return_qty, 0) + COALESCE(w.web_return_qty, 0) AS total_return_qty,
        COALESCE(s.store_net_loss, 0) + COALESCE(w.web_net_loss, 0) AS total_net_loss
    FROM store_item s
    FULL OUTER JOIN web_item w ON s.item_sk = w.item_sk
),
item_hour_counts AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        td.t_hour,
        SUM(sr.sr_return_quantity) AS qty
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    GROUP BY sr.sr_item_sk, td.t_hour
    UNION ALL
    SELECT
        wr.wr_item_sk AS item_sk,
        td.t_hour,
        SUM(wr.wr_return_quantity) AS qty
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY wr.wr_item_sk, td.t_hour
),
item_top_hour AS (
    SELECT
        item_sk,
        t_hour,
        qty,
        ROW_NUMBER() OVER (PARTITION BY item_sk ORDER BY qty DESC) AS rn
    FROM item_hour_counts
),
item_page_type AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        wp.wp_type,
        SUM(wr.wr_return_quantity) AS qty_type
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY wr.wr_item_sk, wp.wp_type
),
item_top_type AS (
    SELECT
        item_sk,
        wp_type,
        qty_type,
        ROW_NUMBER() OVER (PARTITION BY item_sk ORDER BY qty_type DESC) AS rn_type
    FROM item_page_type
)
SELECT
    ci.item_sk,
    ci.store_return_qty,
    ci.web_return_qty,
    ci.total_return_qty,
    ci.total_net_loss,
    ith.t_hour AS top_return_hour,
    ith.qty AS top_hour_qty,
    itp.wp_type AS top_page_type,
    itp.qty_type AS top_page_type_qty,
    RANK() OVER (ORDER BY ci.total_return_qty DESC) AS qty_rank,
    CASE
        WHEN ci.store_return_qty > 0 AND ci.web_return_qty > 0 THEN 'BOTH_CHANNELS'
        WHEN ci.store_return_qty > 0 THEN 'STORE_ONLY'
        WHEN ci.web_return_qty > 0 THEN 'WEB_ONLY'
        ELSE 'NO_RETURNS'
    END AS channel_presence
FROM combined_items ci
LEFT JOIN item_top_hour ith ON ci.item_sk = ith.item_sk AND ith.rn = 1
LEFT JOIN item_top_type itp ON ci.item_sk = itp.item_sk AND itp.rn_type = 1
WHERE ci.total_return_qty > 0
ORDER BY qty_rank
LIMIT 10
