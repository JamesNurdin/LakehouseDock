WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_wholesale_cost,
        cs.cs_list_price
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_ext_sales_price > 100
      AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2452285
)
SELECT
    w.w_warehouse_name,
    i.i_brand,
    i.i_units,
    promo_word,
    COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_net_profit) AS avg_profit,
    MIN(fs.cs_ext_sales_price) AS min_sales,
    MAX(fs.cs_ext_sales_price) AS max_sales,
    CASE
        WHEN SUM(fs.cs_ext_sales_price) > 100000 THEN 'High'
        ELSE 'Medium'
    END AS sales_category,
    (
        SELECT ROUND(AVG(cs2.cs_ext_sales_price), 2)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
    ) AS avg_item_sales_price
FROM filtered_sales fs
JOIN tpcds.item i
    ON fs.cs_item_sk = i.i_item_sk
JOIN tpcds.warehouse w
    ON fs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p
    ON fs.cs_promo_sk = p.p_promo_sk
CROSS JOIN UNNEST(split(p.p_promo_name, ' ')) AS t(promo_word)
WHERE i.i_units = 'Lb'
  AND i.i_wholesale_cost >= 0.50
  AND w.w_county = 'Huron County'
  AND p.p_cost > 500
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY w.w_warehouse_name,
         i.i_brand,
         i.i_units,
         i.i_item_sk,
         promo_word
HAVING COUNT(DISTINCT fs.cs_order_number) > 10
ORDER BY total_sales DESC
LIMIT 100
