WITH filtered_sales AS (
   SELECT
       ws.ws_item_sk,
       ws.ws_ext_sales_price,
       i.i_item_id,
       i.i_product_name,
       i.i_class_id,
       i.i_rec_start_date,
       ca_bill.ca_city AS ca_city,
       ca_ship.ca_state AS ca_state
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
   JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
   WHERE i.i_class_id IN (2, 8, 13)
     AND ca_bill.ca_city = 'Springfield'
     AND ca_ship.ca_state = 'CA'
     AND i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2002-12-31'
     AND ws.ws_ext_sales_price > 100
     AND EXISTS (
         SELECT 1
         FROM inventory inv
         WHERE inv.inv_item_sk = i.i_item_sk
           AND inv.inv_quantity_on_hand > 100
     )
),
aggregated AS (
   SELECT
       i_item_id,
       i_product_name,
       i_class_id,
       ca_city,
       SUM(ws_ext_sales_price) AS total_sales
   FROM filtered_sales
   GROUP BY i_item_id, i_product_name, i_class_id, ca_city
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.i_class_id,
    a.ca_city,
    a.total_sales,
    RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY sales_rank
LIMIT 100
