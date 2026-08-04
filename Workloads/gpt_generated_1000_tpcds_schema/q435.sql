/* goal: Identify top-selling items (including returns) that belong to BrandX and have inventory on hand, ranking them by net sales */
WITH union_sales AS (
    /* Net sales per item from store sales */
    SELECT i.i_item_id,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY i.i_item_id
    UNION
    /* Net sales impact from catalog returns (treated as negative sales) */
    SELECT i.i_item_id,
           -SUM(cr.cr_return_amount) AS total_sales
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY i.i_item_id
),
intersect_set AS (
    /* Keep only items that are BrandX and have inventory on hand */
    SELECT us.i_item_id,
           us.total_sales
    FROM union_sales us
    INTERSECT
    SELECT i.i_item_id,
           CAST(0 AS decimal(7,2)) AS total_sales
    FROM item i
    WHERE i.i_brand = 'BrandX'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 0
      )
)
SELECT i_item_id,
       total_sales,
       row_number() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM intersect_set
ORDER BY total_sales DESC
LIMIT 100
