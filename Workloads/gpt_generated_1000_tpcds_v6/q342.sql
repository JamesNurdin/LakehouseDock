SELECT DISTINCT
    order_id,
    i_item_id,
    warehouse_id,
    promo_name,
    net_paid,
    net_profit,
    max_promo_cost
FROM (
    SELECT
        cs.cs_order_number AS order_id,
        i.i_item_id,
        w.w_warehouse_id AS warehouse_id,
        p.p_promo_name AS promo_name,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        (SELECT max(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS max_promo_cost
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE w.w_county = 'Richland County'
      AND p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
                               AND ws.ws_order_number = wr.wr_order_number
          WHERE ws.ws_item_sk = cs.cs_item_sk
            AND ws.ws_order_number = cs.cs_order_number
      )
    UNION ALL
    SELECT
        ws.ws_order_number AS order_id,
        i.i_item_id,
        w.w_warehouse_id AS warehouse_id,
        p.p_promo_name AS promo_name,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        (SELECT max(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS max_promo_cost
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE w.w_warehouse_id = 'AAAAAAAADBAAAAAA'
      AND p.p_channel_catalog = 'N'
) AS combined
ORDER BY net_profit DESC
LIMIT 100
