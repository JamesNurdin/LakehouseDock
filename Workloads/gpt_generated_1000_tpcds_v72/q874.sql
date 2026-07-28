WITH combined_sales AS (
    SELECT
        i.i_category AS category,
        cs.cs_ext_sales_price AS sales_amount,
        'Catalog' AS source
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE td.t_meal_time = 'MORNING'
      AND cs.cs_ext_sales_price > (
          SELECT AVG(cs2.cs_ext_sales_price)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_time_sk = cs.cs_sold_time_sk
      )
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = cs.cs_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY i.i_category, cs.cs_ext_sales_price
    UNION ALL
    SELECT
        i.i_category AS category,
        ws.ws_ext_sales_price AS sales_amount,
        'Web' AS source
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE td.t_meal_time = 'MORNING'
      AND ws.ws_ext_sales_price > (
          SELECT AVG(ws2.ws_ext_sales_price)
          FROM web_sales ws2
          WHERE ws2.ws_sold_time_sk = ws.ws_sold_time_sk
      )
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ws.ws_promo_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY i.i_category, ws.ws_ext_sales_price
)
SELECT
    category,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT source) AS channel_count
FROM combined_sales
GROUP BY category
HAVING SUM(sales_amount) > 10000
ORDER BY total_sales DESC
LIMIT 100
