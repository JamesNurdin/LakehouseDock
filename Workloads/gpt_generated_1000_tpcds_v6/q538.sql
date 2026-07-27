WITH avg_profit AS (
   SELECT AVG(cs.cs_net_profit) AS avg_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
),
warehouse_sales AS (
   SELECT
       w.w_warehouse_name AS entity_name,
       w.w_city AS city,
       DATE_TRUNC('month', d.d_date) AS period,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(*) AS order_cnt,
       CONCAT(i.i_brand, '-', i.i_color) AS brand_color,
       REGEXP_EXTRACT(i.i_product_name, '([A-Za-z]+)', 1) AS first_word,
       CASE WHEN REGEXP_LIKE(i.i_product_name, '\\d{3}') THEN 'Has3Digits' ELSE 'NoDigits' END AS digit_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_product_name LIKE '% %'                     -- contains a space
     AND REGEXP_LIKE(i.i_product_name, '^[A-Z]{2,}')    -- starts with two+ uppercase letters
     AND cs.cs_net_profit > (SELECT avg_profit FROM avg_profit)
   GROUP BY w.w_warehouse_name, w.w_city, DATE_TRUNC('month', d.d_date), i.i_brand, i.i_color, i.i_product_name
),
callcenter_sales AS (
   SELECT
       cc.cc_name AS entity_name,
       cc.cc_city AS city,
       DATE_TRUNC('year', d.d_date) AS period,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       COUNT(*) AS order_cnt,
       NULL AS brand_color,
       NULL AS first_word,
       NULL AS digit_flag
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year = 2001
     AND cc.cc_name LIKE '%Center%'
     AND cs.cs_net_profit > (SELECT avg_profit FROM avg_profit)
   GROUP BY cc.cc_name, cc.cc_city, DATE_TRUNC('year', d.d_date)
)
SELECT *
FROM warehouse_sales ws
WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd
    WHERE hd.hd_buy_potential LIKE '%5000%'
)
UNION ALL
SELECT *
FROM callcenter_sales
ORDER BY total_sales DESC
LIMIT 100
