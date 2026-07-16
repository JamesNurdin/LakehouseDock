WITH sales_union AS (
    SELECT cs.cs_sold_date_sk AS date_sk, cs.cs_item_sk AS item_sk, cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk, ss.ss_item_sk, ss.ss_net_profit
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_net_profit
    FROM web_sales ws
), monthly_category_sales AS (
    SELECT d.d_year, d.d_month_seq AS month_seq, i.i_category, SUM(su.net_profit) AS net_profit
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT d_year, month_seq, i_category, net_profit
FROM (
    SELECT d_year, month_seq, i_category, net_profit,
           row_number() OVER (PARTITION BY d_year, month_seq ORDER BY net_profit DESC) AS rn
    FROM monthly_category_sales
) t
WHERE rn <= 10
ORDER BY d_year, month_seq, rn
