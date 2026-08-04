WITH max_sale AS (
    SELECT max(sale_amount) AS max_amount FROM (
        SELECT cs_net_paid AS sale_amount FROM catalog_sales
        UNION ALL
        SELECT ws_net_paid AS sale_amount FROM web_sales
    ) AS all_sales
)
SELECT
    d.d_year AS d_year,
    d.d_month_seq AS month_seq,
    'catalog' AS sales_channel,
    SUM(cs.cs_net_paid) AS total_net_paid,
    CASE WHEN SUM(cs.cs_net_paid) > (SELECT max_amount FROM max_sale) THEN 'Above Max' ELSE 'Below Max' END AS sales_category
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_month_seq

UNION ALL

SELECT
    d.d_year AS d_year,
    d.d_month_seq AS month_seq,
    'web' AS sales_channel,
    SUM(ws.ws_net_paid) AS total_net_paid,
    CASE WHEN SUM(ws.ws_net_paid) > (SELECT max_amount FROM max_sale) THEN 'Above Max' ELSE 'Below Max' END AS sales_category
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, d.d_month_seq

ORDER BY d_year, month_seq, sales_channel
LIMIT 100
