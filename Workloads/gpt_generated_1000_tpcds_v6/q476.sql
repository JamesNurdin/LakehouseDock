WITH catalog_data AS (
    SELECT
        'catalog' AS source,
        date_dim.d_year,
        item.i_category,
        SUM(catalog_sales.cs_ext_sales_price) AS total_sales,
        SUM(catalog_sales.cs_net_profit) AS total_profit,
        CASE WHEN SUM(catalog_sales.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        (SELECT avg(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = item.i_category) AS avg_price_category
    FROM catalog_sales
    JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    JOIN customer ON catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
    WHERE date_dim.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND item.i_category = 'Sports'
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd
          WHERE cd.cd_demo_sk = customer.c_current_cdemo_sk
            AND cd.cd_gender = 'F'
      )
    GROUP BY date_dim.d_year, item.i_category
),
web_data AS (
    SELECT
        'web' AS source,
        date_dim.d_year,
        item.i_category,
        SUM(web_sales.ws_ext_sales_price) AS total_sales,
        SUM(web_sales.ws_net_profit) AS total_profit,
        CASE WHEN SUM(web_sales.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        (SELECT avg(i2.i_current_price)
         FROM item i2
         WHERE i2.i_category = item.i_category) AS avg_price_category
    FROM web_sales
    JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN item ON web_sales.ws_item_sk = item.i_item_sk
    JOIN customer ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    WHERE date_dim.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND item.i_category = 'Sports'
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd
          WHERE cd.cd_demo_sk = customer.c_current_cdemo_sk
            AND cd.cd_gender = 'F'
      )
    GROUP BY date_dim.d_year, item.i_category
)
SELECT
    source,
    d_year,
    i_category,
    total_sales,
    total_profit,
    profit_flag,
    avg_price_category
FROM catalog_data
UNION ALL
SELECT
    source,
    d_year,
    i_category,
    total_sales,
    total_profit,
    profit_flag,
    avg_price_category
FROM web_data
ORDER BY total_sales DESC
LIMIT 100
