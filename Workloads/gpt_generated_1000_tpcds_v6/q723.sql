WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    inv_agg.total_on_hand,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    (SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt)) / NULLIF(SUM(cs.cs_ext_sales_price), 0) AS net_sales_ratio
FROM catalog_sales cs
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
WHERE cs.cs_sales_price > 20.0
  AND cs.cs_ship_date_sk BETWEEN 2450000 AND 2459999
  AND w.w_state IN ('CA', 'TX', 'NY')
  AND i.i_brand_id IN (101, 202, 303)
  AND i.i_category = 'Electronics'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
          AND ss2.ss_ext_sales_price > 5000
        LIMIT 1
  )
GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    inv_agg.total_on_hand
HAVING SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_catalog_sales DESC
LIMIT 100
