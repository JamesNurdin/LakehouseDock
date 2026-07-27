WITH sales_with_returns AS (
   SELECT
       i.i_item_id,
       d_sold.d_year AS year,
       SUM(cs.cs_net_profit) AS total_sales_profit,
       SUM(wr.wr_net_loss) AS total_return_loss,
       COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
       RANK() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN web_returns wr ON cs.cs_order_number = wr.wr_order_number
                       AND cs.cs_item_sk = wr.wr_item_sk
   JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
   WHERE d_sold.d_year = 1998
   GROUP BY i.i_item_id, d_sold.d_year
),
sales_without_returns AS (
   SELECT
       i.i_item_id,
       d_sold.d_year AS year,
       SUM(cs.cs_net_profit) AS total_sales_profit,
       0.0 AS total_return_loss,
       COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
       RANK() OVER (PARTITION BY d_sold.d_year ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
   FROM catalog_sales cs
   JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d_sold.d_year = 1998
     AND NOT EXISTS (
         SELECT 1 FROM web_returns wr
         WHERE wr.wr_order_number = cs.cs_order_number
           AND wr.wr_item_sk = cs.cs_item_sk
     )
   GROUP BY i.i_item_id, d_sold.d_year
),
combined AS (
   SELECT * FROM sales_with_returns
   UNION ALL
   SELECT * FROM sales_without_returns
)
SELECT DISTINCT
   c.i_item_id,
   c.year,
   c.total_sales_profit,
   c.total_return_loss,
   c.orders_cnt,
   c.profit_rank,
   (SELECT AVG(cs2.cs_net_profit)
    FROM catalog_sales cs2
    JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = c.year) AS avg_year_profit
FROM combined c
JOIN item i ON c.i_item_id = i.i_item_id
ORDER BY c.year DESC, c.total_sales_profit DESC
LIMIT 100
