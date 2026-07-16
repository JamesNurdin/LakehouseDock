WITH combined_sales AS (
   SELECT ss_sold_date_sk AS sold_date_sk,
          ss_item_sk AS item_sk,
          ss_quantity AS quantity,
          ss_net_paid AS net_paid,
          ss_net_profit AS net_profit
   FROM store_sales
   UNION ALL
   SELECT cs_sold_date_sk,
          cs_item_sk,
          cs_quantity,
          cs_net_paid,
          cs_net_profit
   FROM catalog_sales
   UNION ALL
   SELECT ws_sold_date_sk,
          ws_item_sk,
          ws_quantity,
          ws_net_paid,
          ws_net_profit
   FROM web_sales
),
sales_agg AS (
   SELECT d.d_year AS year,
          i.i_item_id,
          i.i_product_name,
          SUM(s.quantity) AS total_quantity,
          SUM(s.net_paid) AS total_sales,
          SUM(s.net_profit) AS total_profit
   FROM combined_sales s
   JOIN date_dim d ON s.sold_date_sk = d.d_date_sk
   JOIN item i ON s.item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, i.i_item_id, i.i_product_name
),
ranked_sales AS (
   SELECT year,
          i_item_id,
          i_product_name,
          total_quantity,
          total_sales,
          total_profit,
          RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
   FROM sales_agg
)
SELECT year,
       i_item_id,
       i_product_name,
       total_quantity,
       total_sales,
       total_profit,
       profit_rank
FROM ranked_sales
WHERE profit_rank <= 10
ORDER BY profit_rank
