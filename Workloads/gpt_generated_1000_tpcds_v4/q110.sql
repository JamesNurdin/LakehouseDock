WITH promo_items AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           p.p_promo_sk,
           p.p_discount_active
    FROM item i
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
)
SELECT sales_year,
       channel,
       total_sales,
       order_count,
       promos_started
FROM (
    SELECT d.d_year AS sales_year,
           'Catalog' AS channel,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           COUNT(*) AS order_count,
           (
               SELECT COUNT(*)
               FROM promotion p
               JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk
               WHERE d2.d_year = d.d_year
           ) AS promos_started
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promo_items pi ON cs.cs_item_sk = pi.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
    GROUP BY d.d_year
    UNION ALL
    SELECT d.d_year AS sales_year,
           'Web' AS channel,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(*) AS order_count,
           (
               SELECT COUNT(*)
               FROM promotion p
               JOIN date_dim d2 ON p.p_start_date_sk = d2.d_date_sk
               WHERE d2.d_year = d.d_year
           ) AS promos_started
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promo_items pi ON ws.ws_item_sk = pi.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
    GROUP BY d.d_year
) AS combined
ORDER BY sales_year ASC, channel ASC
LIMIT 100
