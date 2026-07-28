WITH combined_sales AS (
    SELECT
        i.i_item_id AS item_id,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_quantity > 0
      AND cs.cs_net_paid > 0
    UNION ALL
    SELECT
        i.i_item_id AS item_id,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        'Web' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
    WHERE ws.ws_quantity > 0
      AND wsi.web_tax_percentage < 0.05
)
SELECT
    item_id,
    COUNT(DISTINCT channel) AS channel_count,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    CASE WHEN SUM(net_profit) > 5000 THEN 'High' ELSE 'Medium' END AS profit_level
FROM combined_sales
GROUP BY item_id
HAVING SUM(net_paid) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
