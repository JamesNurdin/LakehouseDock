WITH sales_union AS (
  SELECT cs_item_sk AS item_sk,
         cs_net_profit AS net_profit,
         cs_sold_date_sk AS date_sk
  FROM catalog_sales
  UNION ALL
  SELECT ws_item_sk AS item_sk,
         ws_net_profit AS net_profit,
         ws_sold_date_sk AS date_sk
  FROM web_sales
),
monthly_brand AS (
  SELECT i.i_brand AS brand,
         d.d_year AS year,
         d.d_month_seq AS month_seq,
         SUM(su.net_profit) AS month_net_profit
  FROM sales_union su
  JOIN item i ON i.i_item_sk = su.item_sk
  JOIN date_dim d ON d.d_date_sk = su.date_sk
  GROUP BY i.i_brand, d.d_year, d.d_month_seq
)
SELECT brand,
       year,
       month_seq,
       month_net_profit,
       AVG(month_net_profit) OVER (PARTITION BY brand ORDER BY year, month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_avg,
       CASE WHEN month_net_profit > AVG(month_net_profit) OVER (PARTITION BY brand ORDER BY year, month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) THEN 'High' ELSE 'Low' END AS profit_category,
       DENSE_RANK() OVER (PARTITION BY brand ORDER BY month_net_profit DESC) AS profit_rank_within_brand
FROM monthly_brand
WHERE year = 2001
ORDER BY brand, year, month_seq
