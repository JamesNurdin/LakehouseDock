WITH catalog_agg AS (
    SELECT 'catalog' AS sales_source,
           ca.ca_country AS country,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_email = 'Y'
      AND sm.sm_type = 'AIR'
      AND ca.ca_country = 'United States'
    GROUP BY ca.ca_country
),
store_agg AS (
    SELECT 'store' AS sales_source,
           ca.ca_country AS country,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE p.p_channel_tv = 'Y'
      AND ca.ca_location_type = 'apartment'
      AND ca.ca_country = 'United States'
    GROUP BY ca.ca_country
)
SELECT sales_source,
       country,
       total_net_profit
FROM catalog_agg
UNION ALL
SELECT sales_source,
       country,
       total_net_profit
FROM store_agg
ORDER BY sales_source,
         country,
         total_net_profit DESC
LIMIT 100
