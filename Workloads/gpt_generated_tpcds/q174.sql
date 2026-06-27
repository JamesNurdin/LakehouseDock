/*
  Total net profit, total discount amount, and sales count per item category
  across Store, Catalog, and Web channels for the year 2001.
*/
WITH store_agg AS (
    SELECT
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
),
catalog_agg AS (
    SELECT
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
),
web_agg AS (
    SELECT
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY i.i_category
)
SELECT
    category,
    channel,
    total_net_profit,
    total_discount,
    sales_cnt,
    CASE WHEN total_net_profit <> 0 THEN total_discount / total_net_profit ELSE NULL END AS discount_to_profit_ratio
FROM (
    SELECT i_category AS category, channel, total_net_profit, total_discount, sales_cnt FROM store_agg
    UNION ALL
    SELECT i_category AS category, channel, total_net_profit, total_discount, sales_cnt FROM catalog_agg
    UNION ALL
    SELECT i_category AS category, channel, total_net_profit, total_discount, sales_cnt FROM web_agg
) t
ORDER BY category, channel
