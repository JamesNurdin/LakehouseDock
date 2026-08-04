WITH catalog_summary AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS sales_year,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY i.i_item_id, d.d_year
),
web_summary AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS sales_year,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY i.i_item_id, d.d_year
),
combined AS (
    SELECT item_id, sales_year, total_sales, 'catalog' AS channel
    FROM catalog_summary
    UNION ALL
    SELECT item_id, sales_year, total_sales, 'web' AS channel
    FROM web_summary
),
items_only_in_catalog AS (
    SELECT item_id FROM catalog_summary
    EXCEPT
    SELECT item_id FROM web_summary
),
customers_both_channels AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    GROUP BY cs.cs_bill_customer_sk
    INTERSECT
    SELECT ws.ws_bill_customer_sk
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
single_date AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2021
    LIMIT 1
)
SELECT
    c.item_id,
    c.sales_year,
    c.total_sales,
    LAG(c.total_sales) OVER (PARTITION BY c.item_id ORDER BY c.sales_year) AS prev_year_sales,
    SUM(c.total_sales) OVER (PARTITION BY c.channel ORDER BY c.sales_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_by_channel,
    c.channel,
    sd.d_date_sk
FROM combined c
CROSS JOIN single_date sd
WHERE c.item_id IN (SELECT item_id FROM items_only_in_catalog)
  AND c.sales_year >= 2020
ORDER BY c.item_id, c.sales_year
LIMIT 100
