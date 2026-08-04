WITH sales_agg AS (
   SELECT cs.cs_item_sk,
          SUM(cs.cs_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   WHERE regexp_like(i.i_item_desc, '[A-Z]{3}')
     AND i.i_color LIKE 'R%'
   GROUP BY cs.cs_item_sk
),
returns_agg AS (
   SELECT cr.cr_item_sk,
          SUM(cr.cr_return_amount) AS total_returns
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   GROUP BY cr.cr_item_sk
),
items_no_returns AS (
   SELECT cs_item_sk FROM sales_agg
   EXCEPT
   SELECT cr_item_sk FROM returns_agg
)
SELECT i.i_item_id,
       i.i_product_name,
       s.total_sales,
       s.sales_cnt,
       substring(i.i_product_name, 1, 10) AS prod_prefix,
       concat(i.i_brand, '_', i.i_category) AS brand_category,
       rp.page_desc,
       rp.page_number_extracted
FROM items_no_returns inr
JOIN sales_agg s ON inr.cs_item_sk = s.cs_item_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
LEFT JOIN LATERAL (
   SELECT cp.cp_description AS page_desc,
          regexp_extract(cp.cp_description, '(\\d+)', 1) AS page_number_extracted
   FROM catalog_sales cs2
   JOIN catalog_page cp ON cs2.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE cs2.cs_item_sk = i.i_item_sk
   ORDER BY cs2.cs_sold_date_sk DESC
   LIMIT 1
) rp ON TRUE
ORDER BY s.total_sales DESC
OFFSET 0
LIMIT 100
