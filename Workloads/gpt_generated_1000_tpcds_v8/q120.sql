WITH filtered_sales AS (
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_call_center_sk,
           cs.cs_catalog_page_sk,
           cs.cs_quantity,
           cs.cs_ext_sales_price,
           cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
      AND cs.cs_ext_sales_price > 1000
)
SELECT d.d_year,
       i.i_category,
       cc.cc_name,
       cp.cp_type,
       SUM(fs.cs_quantity)               AS total_quantity,
       SUM(fs.cs_ext_sales_price)        AS total_sales,
       AVG(fs.cs_net_profit)             AS avg_profit,
       COUNT(DISTINCT fs.cs_item_sk)     AS distinct_items,
       MIN(fs.cs_ext_sales_price)        AS min_sale,
       MAX(fs.cs_ext_sales_price)        AS max_sale
FROM filtered_sales fs
JOIN date_dim d
  ON fs.cs_sold_date_sk = d.d_date_sk
JOIN item i
  ON fs.cs_item_sk = i.i_item_sk
JOIN call_center cc
  ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
 AND inv.inv_item_sk = i.i_item_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
 AND ss.ss_item_sk = i.i_item_sk
JOIN web_site w
  ON w.web_open_date_sk = d.d_date_sk
WHERE i.i_color = 'Blue'
  AND cc.cc_state = 'CA'
  AND cp.cp_type = 'A'
  AND s.s_state = 'CA'
  AND w.web_country = 'United States'
  AND d.d_month_seq BETWEEN 1200 AND 1212
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_sold_date_sk = d.d_date_sk
          AND ss2.ss_net_paid < 0
          AND ss2.ss_item_sk = i.i_item_sk
   )
GROUP BY d.d_year, i.i_category, cc.cc_name, cp.cp_type
ORDER BY total_sales DESC
LIMIT 100
