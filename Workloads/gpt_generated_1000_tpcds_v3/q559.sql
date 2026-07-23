SELECT i_item_id, i_category, net_profit, channel
FROM (
    SELECT i.i_item_id,
           i.i_category,
           SUM(ss.ss_net_profit) AS net_profit,
           'store' AS channel
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE i.i_color = 'red'
      AND s.s_state = 'CA'
      AND t.t_hour >= 12
    GROUP BY i.i_item_id, i.i_category
    UNION ALL
    SELECT i.i_item_id,
           i.i_category,
           SUM(cs.cs_net_profit) AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE i.i_color = 'red'
      AND cc.cc_state = 'CA'
      AND t.t_hour >= 12
    GROUP BY i.i_item_id, i.i_category
) AS combined
ORDER BY net_profit DESC
LIMIT 100
