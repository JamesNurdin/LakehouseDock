WITH
item_sales AS (
   SELECT
       i.i_category AS metric,
       SUM(ss.ss_ext_sales_price) AS value,
       ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rank,
       'ItemSales' AS source,
       regexp_extract(i.i_item_desc, '(\\d{3})') AS three_digit_code,
       CASE WHEN i.i_container LIKE '%BOX%' THEN 'Boxed' ELSE 'Other' END AS container_type
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE regexp_like(i.i_item_desc, '[A-Za-z]{5,}')
   GROUP BY i.i_category, i.i_item_desc, i.i_container
),
income_sales AS (
   SELECT
       CONCAT('Income_', CAST(ib.ib_upper_bound AS VARCHAR)) AS metric,
       SUM(ss.ss_ext_sales_price) AS value,
       ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rank,
       'IncomeSales' AS source
   FROM store_sales ss
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE hd.hd_buy_potential LIKE '%HIGH%'
     AND regexp_like(CAST(ib.ib_upper_bound AS VARCHAR), '^[0-9]+$')
   GROUP BY ib.ib_upper_bound
)
SELECT metric, value, rank, source
FROM item_sales
UNION ALL
SELECT metric, value, rank, source
FROM income_sales
ORDER BY value DESC
LIMIT 100
