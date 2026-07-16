SELECT
    d.d_year,
    i.i_category,
    all_sales.channel,
    SUM(all_sales.net_paid) AS total_net_paid,
    SUM(all_sales.net_profit) AS total_net_profit,
    AVG(all_sales.net_paid) AS avg_net_paid,
    COUNT(*) AS sales_transactions
FROM (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
) AS all_sales
JOIN date_dim d ON all_sales.sold_date_sk = d.d_date_sk
JOIN item i ON all_sales.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, i.i_category, all_sales.channel
ORDER BY d.d_year, total_net_paid DESC
LIMIT 100
