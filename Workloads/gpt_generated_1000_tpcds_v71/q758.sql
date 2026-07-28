WITH sales_items AS (
    SELECT cs.cs_item_sk,
           cs.cs_quantity,
           cs.cs_ext_sales_price,
           cs.cs_ext_ship_cost,
           cs.cs_net_paid_inc_ship,
           cs.cs_order_number,
           i.i_item_id,
           i.i_brand,
           i.i_category,
           i.i_wholesale_cost,
           i.i_container
    FROM catalog_sales cs
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_net_paid_inc_ship > 3000
      AND cs.cs_ext_ship_cost < 500
      AND i.i_wholesale_cost >= 1.00
      AND i.i_container = 'Unknown'
      AND cs.cs_quantity >= 2
)
SELECT si.i_item_id,
       si.i_brand,
       si.i_category,
       SUM(si.cs_ext_sales_price) AS total_sales,
       AVG(si.cs_net_paid_inc_ship) AS avg_paid_inc_ship,
       COUNT(DISTINCT si.cs_order_number) AS order_count,
       MIN(si.cs_ext_ship_cost) AS min_ship_cost,
       MAX(si.cs_ext_ship_cost) AS max_ship_cost
FROM sales_items si
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = si.cs_item_sk
      AND sr.sr_return_amt_inc_tax > 1000
)
GROUP BY si.i_item_id, si.i_brand, si.i_category
HAVING SUM(si.cs_ext_sales_price) > 10000
   AND AVG(si.cs_net_paid_inc_ship) > 3500
ORDER BY total_sales DESC
LIMIT 100
