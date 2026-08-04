WITH catalog_agg AS (
    SELECT
        i.i_item_sk AS i_item_sk,
        t.t_time AS t_time,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
    GROUP BY GROUPING SETS (
        (i.i_item_sk, t.t_time),
        (i.i_item_sk)
    )
),
web_agg AS (
    SELECT
        i.i_item_sk AS i_item_sk,
        t.t_time AS t_time,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 8 AND 12
    GROUP BY GROUPING SETS (
        (i.i_item_sk, t.t_time),
        (i.i_item_sk)
    )
),
combined AS (
    SELECT i_item_sk, t_time, net_paid, distinct_orders FROM catalog_agg
    UNION ALL
    SELECT i_item_sk, t_time, net_paid, distinct_orders FROM web_agg
),
except_items AS (
    SELECT i_item_sk FROM catalog_agg
    EXCEPT
    SELECT i_item_sk FROM web_agg
),
intersect_items AS (
    SELECT i_item_sk FROM catalog_agg
    INTERSECT
    SELECT i_item_sk FROM web_agg
)
SELECT
    ROW_NUMBER() OVER (ORDER BY combined.net_paid DESC) AS row_num,
    combined.i_item_sk,
    combined.t_time,
    combined.net_paid,
    combined.distinct_orders
FROM combined
WHERE combined.i_item_sk IN (SELECT i_item_sk FROM intersect_items)
  AND combined.i_item_sk NOT IN (SELECT i_item_sk FROM except_items)
ORDER BY combined.net_paid DESC, combined.i_item_sk
LIMIT 100
