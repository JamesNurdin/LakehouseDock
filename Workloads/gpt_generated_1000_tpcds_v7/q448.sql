WITH catalog_agg AS (
    SELECT
        p.p_promo_id,
        'catalog' AS sales_channel,
        SUM(cs.cs_net_profit) AS net_profit
    FROM tpcds.catalog_sales cs
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_channel_tv = 'Y'
      AND w.w_city = 'Fairview'
    GROUP BY p.p_promo_id
),
web_agg AS (
    SELECT
        p.p_promo_id,
        'web' AS sales_channel,
        SUM(ws.ws_net_profit) AS net_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_channel_tv = 'Y'
      AND w.w_city = 'Fairview'
    GROUP BY p.p_promo_id
)
SELECT ca.p_promo_id,
       ca.sales_channel,
       ca.net_profit
FROM catalog_agg ca
UNION ALL
SELECT wa.p_promo_id,
       wa.sales_channel,
       wa.net_profit
FROM web_agg wa
ORDER BY p_promo_id, sales_channel
