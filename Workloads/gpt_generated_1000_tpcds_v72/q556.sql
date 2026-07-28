WITH filtered_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        c.c_customer_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2020
      AND regexp_like(i.i_item_desc, '(?i)Premium')
      AND c.c_last_name LIKE 'A%'
      AND concat(ca.ca_city, ', ', ca.ca_state) LIKE '%York%'
)
SELECT
    fs.i_category,
    fs.i_class,
    fs.i_brand,
    sum(fs.cs_net_paid) AS total_sales,
    avg(fs.cs_ext_discount_amt) AS avg_discount,
    count(*) AS sales_count
FROM filtered_sales fs
WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
        WHERE sr.sr_item_sk = fs.i_item_sk
          AND sr.sr_customer_sk = fs.c_customer_sk
          AND dr.d_year = 2020
    )
GROUP BY fs.i_category, fs.i_class, fs.i_brand
HAVING sum(fs.cs_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
