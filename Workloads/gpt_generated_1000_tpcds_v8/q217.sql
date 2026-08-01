WITH cs_agg AS (
    SELECT
        catalog_sales.cs_bill_customer_sk AS customer_sk,
        SUM(catalog_sales.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim
        ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2020
    GROUP BY catalog_sales.cs_bill_customer_sk
    HAVING SUM(catalog_sales.cs_ext_sales_price) > 10000
),
ws_agg AS (
    SELECT
        web_sales.ws_bill_customer_sk AS customer_sk,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM web_sales
    JOIN date_dim
        ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2020
    GROUP BY web_sales.ws_bill_customer_sk
    HAVING SUM(web_sales.ws_ext_sales_price) > 10000
)
SELECT
    customer_sk,
    total_sales,
    order_count
FROM cs_agg
INTERSECT
SELECT
    customer_sk,
    total_sales,
    order_count
FROM ws_agg
ORDER BY total_sales DESC
