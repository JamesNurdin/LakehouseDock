WITH avg_profit AS (
    SELECT AVG(ws_net_profit) AS avg_ws_net_profit
    FROM web_sales
)
SELECT
    wsi.web_name,
    sm.sm_type,
    concat('Site:', wsi.web_name, '|Mode:', sm.sm_type) AS site_mode_label,
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
    substring(wp.wp_url, 1, 30) AS url_prefix,
    sum(ws.ws_net_profit) AS total_net_profit,
    sum(wr.wr_net_loss) AS total_return_loss,
    sum(ws.ws_net_profit) - coalesce(sum(wr.wr_net_loss), 0) AS net_profit_after_returns,
    CASE
        WHEN sum(ws.ws_net_profit) > (SELECT avg_ws_net_profit FROM avg_profit) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
WHERE regexp_like(wp.wp_url, '^https?://.*product.*$')
  AND wp.wp_url LIKE '%/sale%'
GROUP BY
    wsi.web_name,
    sm.sm_type,
    concat('Site:', wsi.web_name, '|Mode:', sm.sm_type),
    regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1),
    substring(wp.wp_url, 1, 30)
ORDER BY total_net_profit DESC
LIMIT 100
