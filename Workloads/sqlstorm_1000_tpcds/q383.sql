WITH sales_all AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS net_profit,
           ss_net_paid AS net_paid,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_net_profit AS net_profit,
           cs_net_paid AS net_paid,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_net_profit AS net_profit,
           ws_net_paid AS net_paid,
           'web' AS channel
    FROM web_sales
),
monthly_sales AS (
    SELECT s.channel,
           i.i_category AS category,
           d.d_year AS sales_year,
           d.d_moy AS month_no,
           SUM(s.net_profit) AS total_profit,
           SUM(s.net_paid) AS total_paid,
           COUNT(*) AS transaction_cnt
    FROM sales_all s
    JOIN date_dim d ON d.d_date_sk = s.date_sk
    JOIN item i ON i.i_item_sk = s.item_sk
    GROUP BY s.channel, i.i_category, d.d_year, d.d_moy
),
ranked_sales AS (
    SELECT channel,
           category,
           sales_year,
           month_no,
           total_profit,
           total_paid,
           transaction_cnt,
           ROW_NUMBER() OVER (PARTITION BY sales_year, channel ORDER BY total_profit DESC) AS category_rank,
           LAG(total_profit) OVER (PARTITION BY channel, category ORDER BY sales_year, month_no) AS prev_month_profit,
           LAG(total_profit) OVER (PARTITION BY channel, category, month_no ORDER BY sales_year) AS prev_year_same_month_profit
    FROM monthly_sales
)
SELECT channel,
       category,
       sales_year,
       month_no,
       total_profit,
       total_paid,
       transaction_cnt,
       category_rank,
       total_profit - COALESCE(prev_month_profit, 0) AS mom_change,
       total_profit - COALESCE(prev_year_same_month_profit, 0) AS yoy_change,
       (total_profit - prev_month_profit) / NULLIF(prev_month_profit, 0) AS mom_pct,
       (total_profit - prev_year_same_month_profit) / NULLIF(prev_year_same_month_profit, 0) AS yoy_pct
FROM ranked_sales
WHERE sales_year = (SELECT MAX(d_year) FROM date_dim)
  AND category_rank <= 10
ORDER BY channel, category_rank, month_no
