WITH store_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        'store' AS channel,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = (SELECT max(d_year) FROM date_dim)
      AND EXISTS (
          SELECT 1 FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
      )
    GROUP BY i.i_item_sk, i.i_item_id
),
web_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        'web' AS channel,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = (SELECT max(d_year) FROM date_dim)
    GROUP BY i.i_item_sk, i.i_item_id
),
union_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
inventory_sample AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS inv_quantity_on_hand
    FROM inventory inv TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = (SELECT max(d_year) FROM date_dim)
    GROUP BY inv.inv_item_sk
)
SELECT
    u.i_item_id AS item_id,
    u.channel,
    SUM(u.total_quantity) AS total_quantity,
    SUM(u.total_net_profit) AS total_net_profit,
    CASE WHEN SUM(u.total_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    SUM(i.inv_quantity_on_hand) AS inventory_on_hand
FROM union_sales u
FULL OUTER JOIN inventory_sample i
    ON u.i_item_sk = i.inv_item_sk
GROUP BY ROLLUP (u.channel, u.i_item_id)
HAVING SUM(u.total_quantity) > 0
ORDER BY profit_category DESC, total_net_profit DESC
