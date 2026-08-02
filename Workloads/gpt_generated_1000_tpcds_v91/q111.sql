WITH sales_agg AS (
    SELECT cs.cs_item_sk AS i_item_sk,
           i.i_product_name,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1915
    GROUP BY cs.cs_item_sk, i.i_product_name
),
returns_agg AS (
    SELECT sr.sr_item_sk AS i_item_sk,
           i.i_product_name,
           SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 1915
    GROUP BY sr.sr_item_sk, i.i_product_name
),
high_sales AS (
    SELECT i_item_sk, i_product_name FROM sales_agg WHERE total_net_profit > 5000
),
high_returns AS (
    SELECT i_item_sk, i_product_name FROM returns_agg WHERE total_return_qty > 100
),
intersect_items AS (
    SELECT i_item_sk, i_product_name FROM high_sales
    INTERSECT
    SELECT i_item_sk, i_product_name FROM high_returns
),
avg_net_profit AS (
    SELECT AVG(total_net_profit) AS avg_profit FROM sales_agg
),
final_metrics AS (
    SELECT i.i_item_sk,
           i.i_product_name,
           s.total_net_profit,
           r.total_return_qty,
           CASE WHEN s.total_net_profit > (SELECT avg_profit FROM avg_net_profit) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
           ROW_NUMBER() OVER (ORDER BY s.total_net_profit DESC) AS profit_rank
    FROM intersect_items i
    JOIN sales_agg s ON i.i_item_sk = s.i_item_sk AND i.i_product_name = s.i_product_name
    JOIN returns_agg r ON i.i_item_sk = r.i_item_sk AND i.i_product_name = r.i_product_name
)
SELECT i_item_sk,
       i_product_name,
       total_net_profit,
       total_return_qty,
       profit_category,
       profit_rank
FROM final_metrics
ORDER BY profit_rank
