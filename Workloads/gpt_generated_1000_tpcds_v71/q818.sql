WITH
  store_sales_data AS (
    SELECT
      'Store' AS sales_channel,
      s.s_store_name AS sales_location,
      CASE WHEN ss.ss_quantity > 5 THEN 'large' ELSE 'small' END AS quantity_group,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND i.i_brand_id IN (SELECT i2.i_brand_id FROM item i2 WHERE i2.i_color = 'Red')
    GROUP BY
      s.s_store_name,
      CASE WHEN ss.ss_quantity > 5 THEN 'large' ELSE 'small' END
  ),
  catalog_sales_data AS (
    SELECT
      'Catalog' AS sales_channel,
      cp.cp_department AS sales_location,
      CASE WHEN cs.cs_quantity > 5 THEN 'large' ELSE 'small' END AS quantity_group,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sales_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND i.i_brand_id IN (SELECT i2.i_brand_id FROM item i2 WHERE i2.i_color = 'Red')
      AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_discount_active = 'Y'
      )
    GROUP BY
      cp.cp_department,
      CASE WHEN cs.cs_quantity > 5 THEN 'large' ELSE 'small' END
  )
SELECT sales_channel,
       sales_location,
       quantity_group,
       total_profit,
       sales_count
FROM store_sales_data
UNION ALL
SELECT sales_channel,
       sales_location,
       quantity_group,
       total_profit,
       sales_count
FROM catalog_sales_data
ORDER BY total_profit DESC
LIMIT 100
