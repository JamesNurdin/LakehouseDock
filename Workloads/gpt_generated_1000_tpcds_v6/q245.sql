WITH store_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'store' AS sales_channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE s.s_county = 'Franklin Parish'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_id, i.i_product_name
),
web_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        'web' AS sales_channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(*) AS txn_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE w.web_name = 'site_4'
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT *
FROM store_data
UNION ALL
SELECT *
FROM web_data
ORDER BY total_net_paid DESC
LIMIT 100
