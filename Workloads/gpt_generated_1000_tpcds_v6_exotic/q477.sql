WITH high_price_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 150
)
SELECT
    ca.ca_state AS state,
    SUM(cs.cs_net_profit) AS total_profit,
    'Catalog' AS channel,
    CASE WHEN SUM(cs.cs_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_tier
FROM catalog_sales cs
JOIN high_price_items h ON cs.cs_item_sk = h.i_item_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
GROUP BY ca.ca_state

UNION ALL

SELECT
    ca.ca_state AS state,
    SUM(ws.ws_net_profit) AS total_profit,
    'Web' AS channel,
    CASE WHEN SUM(ws.ws_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_tier
FROM web_sales ws
JOIN high_price_items h ON ws.ws_item_sk = h.i_item_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2459999
GROUP BY ca.ca_state

ORDER BY total_profit DESC
LIMIT 100
