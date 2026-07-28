/*
Goal: List distinct items sold in 2001 through both the catalog and web channels, showing the sales amount and promotion name for each item. The query combines catalog and web sales using a set operation, removes duplicate rows, and returns the top 100 rows by sales amount.
*/
WITH catalog AS (
    SELECT DISTINCT
        cs.cs_item_sk AS item_sk,
        cs.cs_ext_sales_price AS sales_amount,
        p.p_promo_name AS promo_name,
        d.d_year AS year
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND cs.cs_ext_sales_price > 100
),
web AS (
    SELECT DISTINCT
        ws.ws_item_sk AS item_sk,
        ws.ws_ext_sales_price AS sales_amount,
        p.p_promo_name AS promo_name,
        d.d_year AS year
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_sales_price > 100
)
SELECT
    item_sk,
    sales_amount,
    promo_name,
    year
FROM catalog
UNION
SELECT
    item_sk,
    sales_amount,
    promo_name,
    year
FROM web
ORDER BY sales_amount DESC
LIMIT 100
