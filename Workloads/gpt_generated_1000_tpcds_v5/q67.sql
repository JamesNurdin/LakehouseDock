WITH filtered_returns AS (
   SELECT
       cr.cr_order_number,
       cr.cr_item_sk,
       cr.cr_return_quantity,
       cr.cr_net_loss,
       cr.cr_returning_addr_sk,
       cr.cr_warehouse_sk,
       ca.ca_city,
       ca.ca_street_type,
       ca.ca_zip,
       cs.cs_ship_date_sk,
       cs.cs_ext_wholesale_cost
   FROM catalog_returns cr
   JOIN customer_address ca
     ON cr.cr_returning_addr_sk = ca.ca_address_sk
   JOIN catalog_sales cs
     ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
   WHERE regexp_like(ca.ca_city, '^A')
     AND ca.ca_street_type LIKE '%Ave%'
     AND regexp_like(ca.ca_zip, '^[0-9]{5}$')
)
SELECT
    w.w_warehouse_name,
    fr.cr_item_sk AS item_sk,
    COUNT(*) AS returns_count,
    SUM(fr.cr_net_loss) AS total_net_loss,
    ROUND(AVG(fr.cr_return_quantity), 2) AS avg_return_qty,
    CONCAT('ZipPrefix_', SUBSTRING(fr.ca_zip FROM 1 FOR 3)) AS zip_prefix,
    (
        SELECT MAX(inner_cr.cr_return_quantity)
        FROM catalog_returns inner_cr
        WHERE inner_cr.cr_item_sk = fr.cr_item_sk
    ) AS max_quantity_for_item
FROM filtered_returns fr
JOIN warehouse w
  ON fr.cr_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1 FROM warehouse w2
    WHERE w2.w_warehouse_sk = w.w_warehouse_sk
      AND regexp_like(w2.w_state, 'A$')
)
GROUP BY w.w_warehouse_name, fr.ca_zip, fr.cr_item_sk
ORDER BY total_net_loss DESC
LIMIT 20
