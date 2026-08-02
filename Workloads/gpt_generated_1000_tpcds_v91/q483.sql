WITH high_margin_items AS (
    SELECT i_item_sk,
           i_category,
           i_brand,
           (i_current_price - i_wholesale_cost) AS margin
    FROM item
    WHERE (i_current_price - i_wholesale_cost) > 20
)
SELECT
    category,
    brand,
    total_sales,
    order_count,
    avg_discount
FROM (
    SELECT
        hi.i_category AS category,
        hi.i_brand AS brand,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count,
        (
            SELECT AVG(cs2.cs_ext_discount_amt)
            FROM catalog_sales cs2
            JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
            WHERE i2.i_category = hi.i_category
              AND (hi.i_brand IS NULL OR i2.i_brand = hi.i_brand)
        ) AS avg_discount
    FROM catalog_sales cs
    JOIN high_margin_items hi ON cs.cs_item_sk = hi.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY GROUPING SETS ((hi.i_category, hi.i_brand), (hi.i_category), ())

    UNION ALL

    SELECT
        hi.i_category AS category,
        hi.i_brand AS brand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count,
        (
            SELECT AVG(ws2.ws_ext_discount_amt)
            FROM web_sales ws2
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            WHERE i2.i_category = hi.i_category
              AND (hi.i_brand IS NULL OR i2.i_brand = hi.i_brand)
        ) AS avg_discount
    FROM web_sales ws
    JOIN high_margin_items hi ON ws.ws_item_sk = hi.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451910
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_order_number = ws.ws_order_number
            AND wr.wr_reason_sk IS NOT NULL
      )
    GROUP BY GROUPING SETS ((hi.i_category, hi.i_brand), (hi.i_category), ())
) AS combined
ORDER BY category, brand, total_sales DESC
LIMIT 100
