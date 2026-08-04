WITH sales_return_full AS (
   SELECT
       cs.cs_order_number AS order_number,
       cs.cs_sold_date_sk AS sold_date_sk,
       cr.cr_returned_date_sk AS returned_date_sk,
       COALESCE(cs.cs_item_sk, cr.cr_item_sk) AS item_sk,
       cs.cs_quantity AS quantity,
       cr.cr_return_quantity AS return_quantity,
       CASE
           WHEN cs.cs_quantity IS NULL THEN 'ReturnOnly'
           WHEN cr.cr_return_quantity IS NULL THEN 'SaleOnly'
           ELSE 'SaleAndReturn'
       END AS transaction_type,
       (
           SELECT SUM(inv_quantity_on_hand)
           FROM inventory inv
           WHERE inv.inv_item_sk = COALESCE(cs.cs_item_sk, cr.cr_item_sk)
       ) AS total_inventory
   FROM catalog_sales cs
   FULL OUTER JOIN catalog_returns cr
       ON cs.cs_order_number = cr.cr_order_number
   WHERE NOT EXISTS (
       SELECT 1
       FROM inventory inv2
       WHERE inv2.inv_item_sk = COALESCE(cs.cs_item_sk, cr.cr_item_sk)
         AND inv2.inv_quantity_on_hand > 0
   )
),
web_sales_summary AS (
   SELECT
       ws.ws_order_number AS order_number,
       ws.ws_sold_date_sk AS sold_date_sk,
       NULL AS returned_date_sk,
       ws.ws_item_sk AS item_sk,
       ws.ws_quantity AS quantity,
       NULL AS return_quantity,
       CASE WHEN ws.ws_quantity > 0 THEN 'WebSale' ELSE 'Unknown' END AS transaction_type,
       (
           SELECT SUM(inv_quantity_on_hand)
           FROM inventory inv
           WHERE inv.inv_item_sk = ws.ws_item_sk
       ) AS total_inventory
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND NOT EXISTS (
         SELECT 1
         FROM inventory inv2
         WHERE inv2.inv_item_sk = ws.ws_item_sk
           AND inv2.inv_quantity_on_hand > 0
     )
)
SELECT
    order_number,
    sold_date_sk,
    returned_date_sk,
    item_sk,
    quantity,
    return_quantity,
    transaction_type,
    total_inventory
FROM sales_return_full
UNION ALL
SELECT
    order_number,
    sold_date_sk,
    returned_date_sk,
    item_sk,
    quantity,
    return_quantity,
    transaction_type,
    total_inventory
FROM web_sales_summary
ORDER BY total_inventory DESC NULLS LAST
LIMIT 100
