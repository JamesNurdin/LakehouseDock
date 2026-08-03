WITH sold_items AS (
   SELECT DISTINCT ws.ws_item_sk AS item_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
returned_items AS (
   SELECT DISTINCT wr.wr_item_sk AS item_sk
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
sold_not_returned AS (
   SELECT item_sk FROM sold_items
   EXCEPT
   SELECT item_sk FROM returned_items
),
store_sold_items AS (
   SELECT DISTINCT ss.ss_item_sk AS item_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
target_items AS (
   SELECT sni.item_sk
   FROM sold_not_returned sni
   INTERSECT
   SELECT si.item_sk FROM store_sold_items si
)
SELECT
   i.i_category,
   i.i_brand,
   COUNT(*) AS total_sales_transactions,
   SUM(ss.ss_net_paid) AS total_net_paid,
   CASE
      WHEN SUM(ss.ss_net_profit) > 0 THEN 'PROFITABLE'
      ELSE 'NON_PROFIT'
   END AS profit_status,
   regexp_extract(i.i_product_name, '([A-Z]{3}[0-9]{2})', 1) AS product_code,
   CONCAT(i.i_brand, ' - ', SUBSTRING(i.i_product_name FROM 1 FOR 10)) AS brand_product_label,
   (SELECT SUM(inv.inv_quantity_on_hand)
    FROM inventory inv
    WHERE inv.inv_item_sk = i.i_item_sk) AS total_inventory_on_hand
FROM target_items ti
JOIN item i ON ti.item_sk = i.i_item_sk
JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND regexp_like(i.i_item_desc, '(?i)brush')
  AND i.i_brand_id IN (6012006, 3001002)
GROUP BY
   i.i_category,
   i.i_brand,
   i.i_product_name,
   i.i_item_desc,
   i.i_item_sk
HAVING COUNT(*) > 5
ORDER BY total_net_paid DESC
LIMIT 20
