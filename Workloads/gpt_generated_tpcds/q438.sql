WITH combined_sales AS (
    SELECT i.i_brand AS brand,
           ss.ss_net_profit AS store_net_profit,
           CAST(0 AS decimal(7,2)) AS catalog_net_profit,
           CAST(0 AS decimal(7,2)) AS web_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_category = 'Electronics'

    UNION ALL

    SELECT i.i_brand AS brand,
           CAST(0 AS decimal(7,2)) AS store_net_profit,
           cs.cs_net_profit AS catalog_net_profit,
           CAST(0 AS decimal(7,2)) AS web_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_category = 'Electronics'

    UNION ALL

    SELECT i.i_brand AS brand,
           CAST(0 AS decimal(7,2)) AS store_net_profit,
           CAST(0 AS decimal(7,2)) AS catalog_net_profit,
           ws.ws_net_profit AS web_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_category = 'Electronics'
),
aggregated AS (
    SELECT brand,
           SUM(store_net_profit) AS store_net_profit,
           SUM(catalog_net_profit) AS catalog_net_profit,
           SUM(web_net_profit) AS web_net_profit,
           SUM(store_net_profit + catalog_net_profit + web_net_profit) AS total_net_profit
    FROM combined_sales
    GROUP BY brand
)
SELECT brand,
       store_net_profit,
       catalog_net_profit,
       web_net_profit,
       total_net_profit,
       ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS brand_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 10
