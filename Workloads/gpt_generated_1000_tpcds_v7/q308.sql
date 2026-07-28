WITH catalog_sales_yearly AS (
    SELECT
        d.d_year AS year,
        'Catalog' AS sales_channel,
        SUM(cs.cs_net_paid) AS total_sales
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cc.cc_name LIKE '%East%'
    GROUP BY d.d_year
),
web_sales_yearly AS (
    SELECT
        d.d_year AS year,
        'Web' AS sales_channel,
        SUM(ws.ws_net_paid) AS total_sales
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND wp.wp_url LIKE 'http%'
    GROUP BY d.d_year
)
SELECT year,
       sales_channel,
       total_sales
FROM catalog_sales_yearly
UNION ALL
SELECT year,
       sales_channel,
       total_sales
FROM web_sales_yearly
ORDER BY year, sales_channel
