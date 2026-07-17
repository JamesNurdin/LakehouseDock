SELECT item_id,
       item_desc,
       channel,
       SUM(quantity) AS total_quantity
FROM (
   SELECT i.i_item_id   AS item_id,
          i.i_item_desc AS item_desc,
          ss.ss_quantity AS quantity,
          'store'       AS channel
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   WHERE td.t_meal_time = 'breakfast'
   UNION ALL
   SELECT i.i_item_id   AS item_id,
          i.i_item_desc AS item_desc,
          ws.ws_quantity AS quantity,
          'web'         AS channel
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
   WHERE td.t_meal_time = 'breakfast'
) AS combined
GROUP BY item_id, item_desc, channel
ORDER BY total_quantity DESC
LIMIT 10
