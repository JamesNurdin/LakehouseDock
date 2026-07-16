SELECT
    d.d_year,
    i.i_category,
    SUM(s.sales_amount) AS total_sales,
    SUM(CASE WHEN i.i_brand = 'Brand#12' THEN s.sales_amount ELSE 0 END) AS brand12_sales
FROM (
    SELECT cs_sold_date_sk AS sold_date_sk, cs_ext_sales_price AS sales_amount, cs_item_sk AS item_sk
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk, ws_ext_sales_price, ws_item_sk
    FROM web_sales
    UNION ALL
    SELECT ss_sold_date_sk, ss_ext_sales_price, ss_item_sk
    FROM store_sales
) s
JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2000
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, i.i_category
