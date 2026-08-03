WITH sampled_ws AS (
   SELECT *
   FROM web_sales
   TABLESAMPLE BERNOULLI (10)
),
joined AS (
   SELECT
       ws.ws_sold_date_sk,
       ws.ws_sold_time_sk,
       ws.ws_item_sk,
       ws.ws_quantity,
       ws.ws_net_profit,
       ws.ws_ext_ship_cost,
       td.t_shift,
       td.t_minute,
       CASE
          WHEN ws.ws_net_profit > 0 THEN 'Profitable'
          WHEN ws.ws_net_profit < 0 THEN 'Loss'
          ELSE 'BreakEven'
       END AS profit_category
   FROM sampled_ws ws
   JOIN time_dim td
       ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_shift IN ('first', 'second')
     AND td.t_minute >= 10
     AND ws.ws_ext_ship_cost BETWEEN 100 AND 600
     AND ws.ws_net_profit IS NOT NULL
     AND ws.ws_quantity > 0
),
ranked AS (
   SELECT
       *,
       ROW_NUMBER() OVER (PARTITION BY t_shift ORDER BY ws_net_profit DESC) AS rn_shift,
       RANK() OVER (ORDER BY ws_net_profit DESC) AS overall_rank
   FROM joined
   WHERE EXISTS (
       SELECT 1 FROM web_sales ws2
       WHERE ws2.ws_item_sk = joined.ws_item_sk
         AND ws2.ws_net_profit > 0
   )
),
union_set AS (
   SELECT profit_category, ws_net_profit
   FROM ranked
   WHERE t_shift = 'first'
   UNION
   SELECT profit_category, ws_net_profit
   FROM ranked
   WHERE t_shift = 'second'
),
except_set AS (
   SELECT ws_sold_date_sk
   FROM ranked
   WHERE profit_category = 'Profitable'
   EXCEPT
   SELECT ws_sold_date_sk
   FROM ranked
   WHERE profit_category = 'Loss'
),
full_joined AS (
   SELECT
       u.profit_category,
       u.ws_net_profit,
       e.ws_sold_date_sk
   FROM union_set u
   FULL OUTER JOIN except_set e
       ON TRUE
),
final AS (
   SELECT
       profit_category,
       ws_net_profit,
       ws_sold_date_sk,
       ROW_NUMBER() OVER (ORDER BY ws_net_profit DESC NULLS LAST) AS final_rank
   FROM full_joined
   WHERE ws_net_profit IS NOT NULL
)
SELECT
   profit_category,
   ws_net_profit,
   ws_sold_date_sk,
   final_rank
FROM final
ORDER BY final_rank
LIMIT 100
