WITH web_sales_agg AS (
   SELECT i.i_item_id,
          i.i_category,
          SUM(ws.ws_net_profit) AS net_profit_ws,
          COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers_ws
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 8 AND 12
   GROUP BY i.i_item_id, i.i_category
),
catalog_sales_agg AS (
   SELECT i.i_item_id,
          i.i_category,
          SUM(cs.cs_net_profit) AS net_profit_cs,
          COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers_cs
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   WHERE t.t_hour BETWEEN 13 AND 17
   GROUP BY i.i_item_id, i.i_category
)
SELECT DISTINCT
   item_id,
   category,
   total_net_profit,
   total_distinct_customers
FROM (
   SELECT i_item_id AS item_id,
          i_category AS category,
          net_profit_ws AS total_net_profit,
          distinct_customers_ws AS total_distinct_customers
   FROM web_sales_agg
   UNION ALL
   SELECT i_item_id AS item_id,
          i_category AS category,
          net_profit_cs AS total_net_profit,
          distinct_customers_cs AS total_distinct_customers
   FROM catalog_sales_agg
) combined
ORDER BY total_net_profit DESC
LIMIT 100
