WITH store_agg AS (
   SELECT 'store' AS entity_type,
          ss_store_sk AS entity_id,
          SUM(ss_net_profit) AS total_profit
   FROM store_sales
   JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
   WHERE time_dim.t_hour BETWEEN 9 AND 17
   GROUP BY ss_store_sk
   HAVING SUM(ss_net_profit) > 1000
),
call_center_agg AS (
   SELECT 'call_center' AS entity_type,
          cs_call_center_sk AS entity_id,
          SUM(cs_net_profit) AS total_profit
   FROM catalog_sales
   JOIN call_center ON catalog_sales.cs_call_center_sk = call_center.cc_call_center_sk
   JOIN time_dim ON catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
   WHERE time_dim.t_hour BETWEEN 9 AND 17
     AND call_center.cc_state = 'CA'
   GROUP BY cs_call_center_sk
   HAVING SUM(cs_net_profit) > 1000
)
SELECT entity_type,
       entity_id,
       total_profit,
       SUM(total_profit) OVER (PARTITION BY entity_type ORDER BY total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM (
   SELECT entity_type, entity_id, total_profit FROM store_agg
   UNION
   SELECT entity_type, entity_id, total_profit FROM call_center_agg
) AS combined
ORDER BY total_profit DESC
LIMIT 100
