WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_manufact,
           i.i_brand,
           i.i_class
    FROM item i
    WHERE i.i_manufact LIKE 'bar%'
      AND regexp_like(i.i_product_name, '\\b[A-Z]{3}[0-9]{2}\\b')
      AND i.i_item_sk IN (
          SELECT p_item_sk
          FROM promotion
          WHERE p_discount_active = 'Y'
      )
)
SELECT
    concat(fi.i_brand, '-', fi.i_class) AS brand_class,
    substring(fi.i_product_name, 1, 15) AS product_name_prefix,
    regexp_extract(fi.i_product_name, '([A-Z]{3}[0-9]{2})', 1) AS product_code,
    count(distinct cs.cs_order_number) AS num_orders,
    sum(cs.cs_net_paid) AS total_catalog_sales,
    sum(cr.cr_net_loss) AS total_return_loss,
    sum(ws.ws_net_paid) AS total_web_sales
FROM filtered_items fi
JOIN catalog_sales cs
      ON cs.cs_item_sk = fi.i_item_sk
JOIN catalog_returns cr
      ON cr.cr_item_sk = fi.i_item_sk
     AND cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws
      ON ws.ws_item_sk = fi.i_item_sk
JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY
    concat(fi.i_brand, '-', fi.i_class),
    substring(fi.i_product_name, 1, 15),
    regexp_extract(fi.i_product_name, '([A-Z]{3}[0-9]{2})', 1)
ORDER BY total_catalog_sales DESC
LIMIT 100
