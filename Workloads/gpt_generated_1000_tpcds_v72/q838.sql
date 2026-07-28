WITH avg_sports_price AS (
    SELECT AVG(i2.i_current_price) AS avg_price
    FROM item i2
    WHERE i2.i_category = 'Sports'
)
SELECT
    'catalog' AS sales_channel,
    d.d_year,
    i.i_category,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE d.d_year = 2000
  AND i.i_current_price > (SELECT avg_price FROM avg_sports_price)
GROUP BY d.d_year, i.i_category

UNION ALL

SELECT
    'web' AS sales_channel,
    d.d_year,
    i.i_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE d.d_year = 2000
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
      )
GROUP BY d.d_year, i.i_category

LIMIT 100
