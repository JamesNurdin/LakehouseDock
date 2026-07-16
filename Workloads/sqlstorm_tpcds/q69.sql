WITH
    catalog_data AS (
        SELECT
            cs.cs_sold_date_sk AS sold_date_sk,
            cs.cs_item_sk AS i_item_sk,
            i.i_product_name,
            SUM(cs.cs_net_profit) AS daily_net_profit,
            SUM(cs.cs_quantity) AS daily_quantity,
            MAX(cs.cs_call_center_sk) AS call_center_sk
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE cs.cs_sold_date_sk IS NOT NULL
        GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, i.i_product_name
    ),
    store_data AS (
        SELECT
            ss.ss_sold_date_sk AS sold_date_sk,
            ss.ss_item_sk AS i_item_sk,
            i.i_product_name,
            SUM(ss.ss_net_profit) AS daily_net_profit,
            SUM(ss.ss_quantity) AS daily_quantity,
            CAST(NULL AS INTEGER) AS call_center_sk
        FROM store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE ss.ss_sold_date_sk IS NOT NULL
        GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk, i.i_product_name
    ),
    web_data AS (
        SELECT
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_item_sk AS i_item_sk,
            i.i_product_name,
            SUM(ws.ws_net_profit) AS daily_net_profit,
            SUM(ws.ws_quantity) AS daily_quantity,
            CAST(NULL AS INTEGER) AS call_center_sk
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE ws.ws_sold_date_sk IS NOT NULL
        GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk, i.i_product_name
    ),
    combined AS (
        SELECT 'catalog' AS channel,
               sold_date_sk,
               i_item_sk,
               i_product_name,
               daily_net_profit,
               daily_quantity,
               call_center_sk
        FROM catalog_data
        UNION ALL
        SELECT 'store' AS channel,
               sold_date_sk,
               i_item_sk,
               i_product_name,
               daily_net_profit,
               daily_quantity,
               call_center_sk
        FROM store_data
        UNION ALL
        SELECT 'web' AS channel,
               sold_date_sk,
               i_item_sk,
               i_product_name,
               daily_net_profit,
               daily_quantity,
               call_center_sk
        FROM web_data
    ),
    avg_item_profit AS (
        SELECT
            i_item_sk,
            AVG(daily_net_profit) AS avg_daily_net_profit
        FROM combined
        GROUP BY i_item_sk
    )
SELECT
    d.d_date,
    c.channel,
    c.i_item_sk,
    c.i_product_name,
    c.daily_quantity,
    c.daily_net_profit,
    COALESCE(cc.cc_name, 'N/A') AS call_center_name,
    CONCAT(c.i_product_name, ' - ', c.channel) AS full_item_desc,
    CASE WHEN c.daily_net_profit > COALESCE(ai.avg_daily_net_profit, 0) THEN 1 ELSE 0 END AS above_avg_flag,
    RANK() OVER (PARTITION BY d.d_date, c.channel ORDER BY c.daily_net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY c.channel ORDER BY c.daily_net_profit DESC) AS overall_profit_rank,
    (SELECT COUNT(*) FROM combined c3 WHERE c3.i_item_sk = c.i_item_sk) AS total_days_sold
FROM combined c
JOIN date_dim d ON c.sold_date_sk = d.d_date_sk
LEFT JOIN call_center cc ON c.call_center_sk = cc.cc_call_center_sk
LEFT JOIN avg_item_profit ai ON c.i_item_sk = ai.i_item_sk
WHERE d.d_year = 2000
  AND (
        (c.channel = 'catalog' AND c.daily_quantity > 5)
        OR (c.channel <> 'catalog' AND c.daily_quantity > 2)
      )
  AND c.daily_net_profit IS NOT NULL
  AND c.daily_net_profit > 0
ORDER BY d.d_date, c.channel, profit_rank
LIMIT 100
