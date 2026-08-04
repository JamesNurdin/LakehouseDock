WITH
    store_items AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_color
        FROM store_sales ss
        JOIN store s
          ON ss.ss_store_sk = s.s_store_sk
        JOIN item i
          ON ss.ss_item_sk = i.i_item_sk
        JOIN time_dim t
          ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN household_demographics hd
          ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE t.t_hour BETWEEN 6 AND 12
          AND t.t_minute IN (6, 16, 18)
          AND hd.hd_vehicle_count > 0
          AND hd.hd_dep_count IN (5, 8)
          AND s.s_state = 'CA'
        GROUP BY i.i_item_sk, i.i_item_id, i.i_color
    ),
    web_items AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_color
        FROM web_sales ws
        JOIN item i
          ON ws.ws_item_sk = i.i_item_sk
        JOIN time_dim t
          ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN household_demographics hd
          ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        WHERE t.t_hour BETWEEN 6 AND 12
          AND t.t_minute IN (6, 16, 18)
          AND hd.hd_vehicle_count > 0
          AND hd.hd_dep_count IN (5, 8)
        GROUP BY i.i_item_sk, i.i_item_id, i.i_color
    )
SELECT common.i_item_id,
       common.i_color,
       common.i_item_sk
FROM (
    SELECT i_item_sk, i_item_id, i_color FROM store_items
    INTERSECT
    SELECT i_item_sk, i_item_id, i_color FROM web_items
) AS common
ORDER BY common.i_item_id
LIMIT 100
