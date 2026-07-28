WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_item_desc,
           i.i_product_name,
           CONCAT('Brand: ', i.i_brand, ' - ', SUBSTRING(i.i_item_desc FROM 1 FOR 20)) AS brand_desc
    FROM tpcds.item i
    WHERE regexp_like(i.i_item_desc, '\\d{4}')
      AND i.i_product_name LIKE '%Deluxe%'
)
SELECT fi.i_brand,
       COUNT(DISTINCT cs.cs_order_number) AS orders,
       SUM(cs.cs_net_paid) AS total_net_paid,
       AVG(cs.cs_net_profit) AS avg_net_profit,
       MIN(fi.brand_desc) AS sample_brand_desc
FROM filtered_items fi
JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = fi.i_item_sk
JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND regexp_like(p.p_channel_email, '^Y$')
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_returns cr
        WHERE cr.cr_item_sk = fi.i_item_sk
          AND cr.cr_return_amount > 100
    )
GROUP BY fi.i_brand
ORDER BY total_net_paid DESC
LIMIT 100
