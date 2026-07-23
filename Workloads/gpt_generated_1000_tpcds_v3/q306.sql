WITH store_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        SUM(ss.ss_net_paid) AS sales_amount,
        'store' AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_channel_tv = 'Y'
      )
    GROUP BY i.i_item_id, i.i_brand
),
web_sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        SUM(ws.ws_net_paid) AS sales_amount,
        'web' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND p.p_channel_tv = 'Y'
    GROUP BY i.i_item_id, i.i_brand
)
SELECT DISTINCT
    agg.item_id,
    agg.brand,
    agg.sales_amount,
    agg.channel
FROM (
    SELECT item_id, brand, sales_amount, channel FROM store_sales_agg
    UNION ALL
    SELECT item_id, brand, sales_amount, channel FROM web_sales_agg
) agg
ORDER BY agg.sales_amount DESC
LIMIT 100
