WITH catalog_data AS (
    SELECT
        i.i_category AS category,
        cs.cs_net_profit AS net_profit,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_end_date <= DATE '2001-12-31'
),
web_data AS (
    SELECT
        i.i_category AS category,
        ws.ws_net_profit AS net_profit,
        CASE WHEN ws.ws_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE wsite.web_rec_start_date >= DATE '2000-01-01'
      AND wsite.web_rec_end_date <= DATE '2001-12-31'
)
SELECT
    combined.category,
    combined.profit_level,
    SUM(combined.net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM (
    SELECT category, profit_level, net_profit FROM catalog_data
    UNION ALL
    SELECT category, profit_level, net_profit FROM web_data
) combined
GROUP BY combined.category, combined.profit_level
ORDER BY total_net_profit DESC
LIMIT 100
