WITH filtered_items AS (
   SELECT 
     i.i_item_sk,
     i.i_item_desc,
     i.i_brand,
     i.i_category,
     CAST(regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS integer) AS three_digit_code,
     concat(i.i_brand, '_', i.i_category) AS brand_category
   FROM 
     item i
   WHERE 
     regexp_like(i.i_item_desc, '\\d{3}')
     AND i.i_brand LIKE 'Brand%'
),
aggregated_sales AS (
   SELECT
     fi.i_item_sk,
     fi.i_item_desc,
     fi.brand_category,
     fi.three_digit_code,
     sm.sm_code,
     sum(ws.ws_ext_sales_price) AS total_sales,
     sum(sr.sr_return_amt) AS total_returns,
     (SELECT MAX(inv.inv_quantity_on_hand)
      FROM inventory inv
      WHERE inv.inv_item_sk = fi.i_item_sk) AS max_qty_on_hand,
     CASE 
       WHEN EXISTS (
         SELECT 1 
         FROM store_returns sr2 
         WHERE sr2.sr_item_sk = fi.i_item_sk 
           AND sr2.sr_return_amt > 100
       ) THEN 1 ELSE 0 END AS has_high_return
   FROM 
     filtered_items fi
     JOIN web_sales ws ON ws.ws_item_sk = fi.i_item_sk
     JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
     LEFT JOIN store_returns sr ON sr.sr_item_sk = fi.i_item_sk
   WHERE 
     sm.sm_code LIKE 'AIR%'
     AND regexp_like(sm.sm_type, 'Express')
   GROUP BY 
     fi.i_item_sk,
     fi.i_item_desc,
     fi.brand_category,
     fi.three_digit_code,
     sm.sm_code
)
SELECT
  ag.i_item_sk,
  ag.i_item_desc,
  ag.brand_category,
  ag.three_digit_code,
  ag.sm_code,
  ag.total_sales,
  ag.total_returns,
  ag.max_qty_on_hand,
  ag.has_high_return,
  row_number() OVER (ORDER BY ag.total_sales DESC) AS sales_rank
FROM aggregated_sales ag
ORDER BY ag.total_sales DESC
LIMIT 100
