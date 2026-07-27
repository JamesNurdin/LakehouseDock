WITH high_profit_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_category,
           i_current_price
    FROM   item
    WHERE  i_current_price > 100
       AND i_category_id IN (3, 5, 7)
),
catalog_agg AS (
    SELECT
        cs.cs_sold_date_sk               AS sold_date_sk,
        hpi.i_item_id,
        hpi.i_category,
        SUM(cs.cs_net_profit)            AS total_profit,
        COUNT(*)                         AS order_count
    FROM   catalog_sales cs
    JOIN   high_profit_items hpi
           ON cs.cs_item_sk = hpi.i_item_sk
    JOIN   warehouse w
           ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN   time_dim t
           ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE  t.t_hour BETWEEN 12 AND 16
      AND EXISTS (
            SELECT 1
            FROM   warehouse w2
            WHERE  w2.w_warehouse_sk = cs.cs_warehouse_sk
               AND w2.w_state = 'CA'
        )
    GROUP BY cs.cs_sold_date_sk, hpi.i_item_id, hpi.i_category
),
web_agg AS (
    SELECT
        ws.ws_sold_date_sk               AS sold_date_sk,
        hpi.i_item_id,
        hpi.i_category,
        SUM(ws.ws_net_profit)            AS total_profit,
        COUNT(*)                         AS order_count
    FROM   web_sales ws
    JOIN   high_profit_items hpi
           ON ws.ws_item_sk = hpi.i_item_sk
    JOIN   warehouse w
           ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN   time_dim t
           ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE  t.t_hour BETWEEN 12 AND 16
      AND EXISTS (
            SELECT 1
            FROM   warehouse w2
            WHERE  w2.w_warehouse_sk = ws.ws_warehouse_sk
               AND w2.w_state = 'CA'
        )
    GROUP BY ws.ws_sold_date_sk, hpi.i_item_id, hpi.i_category
)
SELECT sold_date_sk,
       i_item_id,
       i_category,
       total_profit,
       order_count
FROM   catalog_agg
UNION ALL
SELECT sold_date_sk,
       i_item_id,
       i_category,
       total_profit,
       order_count
FROM   web_agg
ORDER BY sold_date_sk,
         total_profit DESC
