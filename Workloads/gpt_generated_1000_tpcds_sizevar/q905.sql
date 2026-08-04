WITH sales_per_store AS (
    SELECT ss.ss_store_sk,
           ss.ss_item_sk,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
)
SELECT DISTINCT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    sp.total_sales,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY sp.total_sales DESC) AS sales_rank
FROM sales_per_store sp
RIGHT OUTER JOIN store s
    ON sp.ss_store_sk = s.s_store_sk
LEFT JOIN item i
    ON sp.ss_item_sk = i.i_item_sk
WHERE s.s_state = 'TX'
  AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
    )

UNION

SELECT DISTINCT
    w.w_warehouse_id,
    w.w_warehouse_name,
    i2.i_item_id,
    i2.i_product_name,
    cs_tot.sales_amount,
    RANK() OVER (PARTITION BY w.w_warehouse_id ORDER BY cs_tot.sales_amount DESC) AS sales_rank
FROM (
        SELECT cs.cs_warehouse_sk,
               cs.cs_item_sk,
               SUM(cs.cs_ext_sales_price) AS sales_amount
        FROM catalog_sales cs
        GROUP BY cs.cs_warehouse_sk, cs.cs_item_sk
    ) cs_tot
RIGHT OUTER JOIN warehouse w
    ON cs_tot.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN item i2
    ON cs_tot.cs_item_sk = i2.i_item_sk
WHERE w.w_state = 'TX'
  AND i2.i_current_price > (SELECT AVG(i3.i_current_price) FROM item i3)
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i2.i_item_sk
          AND p2.p_discount_active = 'Y'
    )
  AND w.w_warehouse_id IN (
        SELECT DISTINCT wp.wp_type
        FROM web_page wp
        WHERE wp.wp_type = 'article'
    )
ORDER BY 1, 2, 6 DESC
LIMIT 100
