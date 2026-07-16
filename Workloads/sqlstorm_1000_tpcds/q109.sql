WITH sales AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit
    FROM web_sales ws
)
SELECT
    d.d_year,
    i.i_category,
    SUM(s.ext_sales_price) AS total_sales,
    SUM(s.net_profit) AS total_profit,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(s.ext_sales_price) DESC) AS sales_rank
FROM sales s
JOIN date_dim d ON d.d_date_sk = s.date_sk
JOIN item i ON i.i_item_sk = s.item_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year, i.i_category
HAVING SUM(s.ext_sales_price) > 1000000
ORDER BY d.d_year, sales_rank
