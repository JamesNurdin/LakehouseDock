WITH intersect_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_event = 'N'
    INTERSECT
    SELECT ss.ss_item_sk
    FROM store_sales ss
    JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
    WHERE p2.p_channel_event = 'N'
)
SELECT 'catalog' AS source,
       cs.cs_order_number AS order_number,
       cs.cs_item_sk AS item_sk,
       cs.cs_sales_price AS sales_price,
       cs.cs_quantity AS quantity
FROM catalog_sales cs
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE p.p_channel_event = 'N'
  AND cs.cs_sales_price > (
        SELECT MAX(p_cost)
        FROM promotion
        WHERE p_discount_active = 'Y'
      )
  AND cs.cs_item_sk IN (SELECT item_sk FROM intersect_items)

UNION ALL

SELECT 'store' AS source,
       ss.ss_ticket_number AS order_number,
       ss.ss_item_sk AS item_sk,
       ss.ss_sales_price AS sales_price,
       ss.ss_quantity AS quantity
FROM store_sales ss
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
WHERE p.p_channel_event = 'N'
  AND ss.ss_sales_price > (
        SELECT MAX(p_cost)
        FROM promotion
        WHERE p_discount_active = 'Y'
      )
  AND ss.ss_item_sk IN (SELECT item_sk FROM intersect_items)

ORDER BY source, order_number
