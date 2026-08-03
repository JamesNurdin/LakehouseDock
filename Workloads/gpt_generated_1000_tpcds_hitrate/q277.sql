WITH cs_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = cs.cs_order_number
    )
    AND regexp_like(CAST(cs.cs_order_number AS varchar), '^[0-9]{6}$')
)
SELECT
    i.i_item_id,
    i.i_product_name,
    concat(i.i_brand, ' ', i.i_product_name) AS full_desc,
    regexp_extract(i.i_product_name, '\\d+', 0) AS extracted_number,
    CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_quantity,
    (SELECT SUM(ss.ss_ext_sales_price)
     FROM store_sales ss
     WHERE ss.ss_item_sk = i.i_item_sk) AS total_store_sales
FROM cs_filtered cs
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE i.i_product_name LIKE '%Widget%'
  AND regexp_like(i.i_product_name, '[A-Z]{2,}')
GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_item_sk
ORDER BY total_store_sales DESC
LIMIT 100
