WITH sales_union AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS net_profit,
           ss_net_paid AS net_paid,
           ss_quantity AS quantity,
           ss_ticket_number AS order_number,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_net_profit AS net_profit,
           cs_net_paid AS net_paid,
           cs_quantity AS quantity,
           cs_order_number AS order_number,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_net_profit AS net_profit,
           ws_net_paid AS net_paid,
           ws_quantity AS quantity,
           ws_order_number AS order_number,
           'web' AS channel
    FROM web_sales
),
sales_with_dim AS (
    SELECT su.*, d.d_year, d.d_quarter_name AS quarter,
           i.i_category, i.i_brand
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
agg AS (
    SELECT d_year,
           quarter,
           i_category,
           i_brand,
           channel,
           SUM(net_profit) AS total_profit,
           SUM(net_paid) AS total_paid,
           SUM(quantity) AS total_quantity,
           COUNT(DISTINCT order_number) AS distinct_orders,
           AVG(net_profit) AS avg_profit_per_order
    FROM sales_with_dim
    GROUP BY d_year, quarter, i_category, i_brand, channel
    HAVING SUM(net_profit) > 0
)
SELECT d_year,
       quarter,
       i_category,
       i_brand,
       channel,
       total_profit,
       total_paid,
       total_quantity,
       distinct_orders,
       avg_profit_per_order,
       ROW_NUMBER() OVER (PARTITION BY d_year, quarter ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, quarter, total_profit DESC
LIMIT 200
