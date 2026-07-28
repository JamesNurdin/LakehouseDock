WITH cat_sales AS (
    SELECT
        d.d_year AS sales_year,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND EXISTS (
            SELECT 1
            FROM tpcds.store_returns sr
            WHERE sr.sr_item_sk = cs.cs_item_sk
              AND sr.sr_returned_date_sk = d.d_date_sk
              AND sr.sr_net_loss > 500
        )
    GROUP BY GROUPING SETS ((d.d_year, i.i_category), (d.d_year), ())
),
web_sales AS (
    SELECT
        d.d_year AS sales_year,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ws.ws_ext_sales_price > (
            SELECT AVG(cs2.cs_ext_sales_price)
            FROM tpcds.catalog_sales cs2
            WHERE cs2.cs_sold_date_sk = d.d_date_sk
        )
    GROUP BY GROUPING SETS ((d.d_year, i.i_category), (d.d_year), ())
)
SELECT
    sales_year,
    category,
    total_sales
FROM (
    SELECT * FROM cat_sales
    UNION ALL
    SELECT * FROM web_sales
) AS combined
ORDER BY sales_year DESC NULLS LAST,
         total_sales DESC
LIMIT 100
