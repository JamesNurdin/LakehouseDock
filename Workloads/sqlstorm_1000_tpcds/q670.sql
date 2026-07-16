WITH all_sales AS (
    SELECT cs.cs_sold_date_sk AS sales_date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_ext_sales_price AS sales_amount,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_ext_sales_price,
           ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_ext_sales_price,
           ws.ws_net_profit
    FROM web_sales ws
),
agg_sales AS (
    SELECT d.d_year,
           i.i_category,
           SUM(s.sales_amount) AS total_sales,
           SUM(s.profit) AS total_profit,
           COUNT(*) AS sales_cnt
    FROM all_sales s
    JOIN date_dim d ON s.sales_date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category
)
SELECT a.d_year,
       a.i_category,
       a.total_sales,
       a.total_profit,
       a.sales_cnt,
       ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.total_sales DESC) AS sales_rank
FROM agg_sales a
ORDER BY a.total_sales DESC
LIMIT 100
