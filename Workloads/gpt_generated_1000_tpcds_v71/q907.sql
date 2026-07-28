WITH cat AS (
    SELECT
        i.i_category AS category,
        SUM(cs.cs_net_profit) AS net_profit,
        CASE WHEN SUM(cs.cs_quantity) > 1000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_level
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451179
    GROUP BY i.i_category
),
web AS (
    SELECT
        i.i_category AS category,
        SUM(ws.ws_net_profit) AS net_profit,
        CASE WHEN SUM(ws.ws_quantity) > 1000 THEN 'High Volume' ELSE 'Low Volume' END AS volume_level
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451179
    GROUP BY i.i_category
)
SELECT
    'Catalog' AS channel,
    category,
    net_profit,
    volume_level
FROM cat
UNION ALL
SELECT
    'Web' AS channel,
    category,
    net_profit,
    volume_level
FROM web
ORDER BY channel, net_profit DESC
