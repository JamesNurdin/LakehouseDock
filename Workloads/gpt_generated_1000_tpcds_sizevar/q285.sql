WITH premium_items AS (
    SELECT i_item_sk,
           i_category,
           i_product_name,
           regexp_extract(i_product_name, '(?i)Premium\s+(.*)', 1) AS product_suffix
    FROM item
    WHERE regexp_like(i_product_name, '(?i)Premium')
)
SELECT di.d_year,
       pi.i_category,
       COUNT(DISTINCT cs.cs_order_number) AS orders,
       SUM(cs.cs_net_profit) AS total_profit,
       AVG(cs.cs_quantity) AS avg_quantity,
       MAX(pi.product_suffix) FILTER (WHERE pi.product_suffix IS NOT NULL) AS example_suffix
FROM catalog_sales cs
JOIN date_dim di ON cs.cs_ship_date_sk = di.d_date_sk
JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
JOIN premium_items pi ON cs.cs_item_sk = pi.i_item_sk
WHERE di.d_year = 2000
  AND cu.c_email_address LIKE '%@%.com'
  AND cu.c_email_address NOT LIKE '%@%.org'
  AND EXISTS (
        SELECT 1
        FROM warehouse w
        WHERE w.w_warehouse_sk = cs.cs_warehouse_sk
          AND w.w_state = 'CA'
    )
GROUP BY di.d_year, pi.i_category
ORDER BY total_profit DESC
LIMIT 100
