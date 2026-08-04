WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        i.i_item_sk,
        i.i_category,
        i.i_size,
        p.p_channel_email,
        cc.cc_call_center_sk,
        sm.sm_ship_mode_sk,
        w.w_warehouse_sk,
        cd.cd_demo_sk,
        cr.cr_return_quantity,
        inv.inv_quantity_on_hand,
        td.t_hour
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                             AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
                             AND ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                           AND ws.ws_sold_time_sk = td.t_time_sk
    WHERE i.i_size = 'large'
      AND p.p_channel_email = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
),
item_agg AS (
    SELECT
        i_item_sk,
        SUM(cs_net_profit) AS cs_profit,
        SUM(ss_net_profit) AS ss_profit,
        SUM(ws_net_profit) AS ws_profit,
        SUM(cs_quantity + ss_quantity + ws_quantity) AS total_quantity
    FROM base
    GROUP BY i_item_sk
)
SELECT
    ia.i_item_sk,
    (ia.cs_profit + ia.ss_profit + ia.ws_profit)            AS total_profit,
    LAG((ia.cs_profit + ia.ss_profit + ia.ws_profit)) OVER (ORDER BY (ia.cs_profit + ia.ss_profit + ia.ws_profit) DESC) AS prev_total_profit,
    (SELECT AVG(cs_quantity) FROM catalog_sales)        AS avg_cs_quantity,
    CASE WHEN ia.i_item_sk NOT IN (SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 0)
         THEN 'No Returns'
         ELSE 'Has Returns'
    END                                                AS return_flag
FROM item_agg ia
WHERE (ia.cs_profit + ia.ss_profit + ia.ws_profit) > (SELECT AVG(cs_quantity) FROM catalog_sales)
  AND ia.i_item_sk NOT IN (SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 0)
ORDER BY total_profit DESC
OFFSET 0
LIMIT 100
