WITH catalog_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           SUM(cs.cs_net_paid) AS total_sales,
           'catalog' AS channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451010 AND 2451200
      AND sm.sm_carrier = 'FEDEX'
      AND p.p_discount_active = 'N'
    GROUP BY i.i_item_id, i.i_category
),
web_agg AS (
    SELECT i.i_item_id,
           i.i_category,
           SUM(ws.ws_net_paid) AS total_sales,
           'web' AS channel
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451010 AND 2451200
      AND sm.sm_carrier = 'FEDEX'
      AND p.p_discount_active = 'N'
    GROUP BY i.i_item_id, i.i_category
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM web_agg
ORDER BY total_sales DESC
LIMIT 100
