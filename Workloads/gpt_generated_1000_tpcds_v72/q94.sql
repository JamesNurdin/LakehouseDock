WITH union_sales AS (
    SELECT
        d.d_date AS sale_date,
        i.i_item_id AS item_id,
        cs.cs_ext_sales_price AS sales_amount,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND ca.ca_location_type = 'condo'
    UNION ALL
    SELECT
        d.d_date AS sale_date,
        i.i_item_id AS item_id,
        ss.ss_ext_sales_price AS sales_amount,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND ca.ca_suite_number LIKE 'Suite %'
      AND ss.ss_ext_sales_price > 0
)
SELECT
    u.item_id,
    year(u.sale_date) AS sale_year,
    SUM(u.sales_amount) AS total_sales,
    (SELECT AVG(v.sales_amount)
       FROM union_sales v
       WHERE v.item_id = u.item_id) AS avg_item_sales
FROM union_sales u
GROUP BY u.item_id, year(u.sale_date)
ORDER BY total_sales DESC
LIMIT 100
