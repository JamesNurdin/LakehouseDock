WITH store_part AS (
    SELECT
        d.d_date AS sales_date,
        'store' AS channel,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        (
            SELECT MAX(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_promo_sk = ss.ss_promo_sk
        ) AS max_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = ss.ss_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY d.d_date, ss.ss_item_sk, ss.ss_promo_sk
),
web_part AS (
    SELECT
        d.d_date AS sales_date,
        'web' AS channel,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        (
            SELECT MAX(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_promo_sk = ws.ws_promo_sk
        ) AS max_promo_cost
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'F'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_date_sk = d.d_date_sk
            AND inv.inv_item_sk = ws.ws_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
    GROUP BY d.d_date, ws.ws_item_sk, ws.ws_promo_sk
)
SELECT sales_date, channel, item_sk, total_sales, max_promo_cost
FROM store_part
UNION ALL
SELECT sales_date, channel, item_sk, total_sales, max_promo_cost
FROM web_part
ORDER BY sales_date DESC, total_sales DESC
LIMIT 100
