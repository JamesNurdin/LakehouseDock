WITH brand_profit_a AS (
    SELECT
        i.i_brand AS brand,
        w.web_name AS site_name,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 100000 THEN 'High'
            WHEN SUM(ws.ws_net_profit) > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        (
            SELECT AVG(ws2.ws_list_price)
            FROM web_sales ws2
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            WHERE i2.i_brand = i.i_brand
        ) AS avg_list_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_rec_end_date = DATE '2000-08-15'
      AND i.i_class = 'pants'
    GROUP BY i.i_brand, w.web_name
),
brand_profit_b AS (
    SELECT
        i.i_brand AS brand,
        w.web_name AS site_name,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE
            WHEN SUM(ws.ws_net_profit) > 80000 THEN 'High'
            WHEN SUM(ws.ws_net_profit) > 30000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        (
            SELECT AVG(ws2.ws_list_price)
            FROM web_sales ws2
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            WHERE i2.i_brand = i.i_brand
        ) AS avg_list_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_rec_end_date = DATE '1999-08-16'
      AND i.i_class = 'sports-apparel'
      AND EXISTS (
          SELECT 1
          FROM item i3
          WHERE i3.i_formulation LIKE '%goldenrod%'
            AND i3.i_brand_id = i.i_brand_id
      )
    GROUP BY i.i_brand, w.web_name
)
SELECT *
FROM brand_profit_a
UNION ALL
SELECT *
FROM brand_profit_b
LIMIT 100
