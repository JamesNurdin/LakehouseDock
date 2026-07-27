WITH store_part AS (
    SELECT
        i.i_brand_id AS brand_id,
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        'store' AS source,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_level,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_brand_id = i.i_brand_id) AS avg_brand_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE i.i_brand_id = 3003001
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_return_quantity > 0
      )
    GROUP BY i.i_brand_id, i.i_item_id, i.i_item_desc
),
catalog_part AS (
    SELECT
        i.i_brand_id AS brand_id,
        i.i_item_id,
        i.i_item_desc,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        'catalog' AS source,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 10000 THEN 'High' ELSE 'Low' END AS sales_level,
        (SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_brand_id = i.i_brand_id) AS avg_brand_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_brand_id = 3003001
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_brand_id, i.i_item_id, i.i_item_desc
)
SELECT
    brand_id,
    i_item_id,
    i_item_desc,
    total_sales,
    source,
    sales_level,
    avg_brand_price
FROM store_part
UNION ALL
SELECT
    brand_id,
    i_item_id,
    i_item_desc,
    total_sales,
    source,
    sales_level,
    avg_brand_price
FROM catalog_part
ORDER BY total_sales DESC, source
LIMIT 100
