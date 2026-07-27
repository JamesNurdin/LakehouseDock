WITH catalog_sales_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_monthly AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    year,
    month,
    category,
    total_net_paid
FROM catalog_sales_monthly
UNION ALL
SELECT
    year,
    month,
    category,
    total_net_paid
FROM web_sales_monthly
ORDER BY year, month, category, total_net_paid DESC
LIMIT 100
