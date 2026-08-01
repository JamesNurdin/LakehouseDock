WITH
    sampled_inventory AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)   -- sample 10% of inventory
    ),
    union_keys AS (
        SELECT cc.cc_call_center_sk AS key FROM call_center cc WHERE cc.cc_state = 'CA'
        UNION ALL
        SELECT cs.cs_call_center_sk FROM catalog_sales cs WHERE cs.cs_call_center_sk IS NOT NULL
    )
SELECT
    c.c_customer_id,
    i.i_product_name,
    td.t_shift,
    CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    COUNT(DISTINCT ws.ws_order_number)           AS distinct_ws_orders,
    COUNT(DISTINCT ca.ca_address_sk)             AS distinct_addresses,
    SUM(ws.ws_net_paid)                           AS total_ws_net_paid,
    SUM(DISTINCT inv.inv_quantity_on_hand)       AS distinct_inventory_qty,
    SUM(DISTINCT p.p_cost)                       AS distinct_promo_cost
FROM
    catalog_sales cs
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td              ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p         ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN promotion p2        ON p2.p_promo_sk = cs.cs_promo_sk AND p2.p_discount_active = 'Y'   -- second alias of promotion
    LEFT JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w         ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr      ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inventory inv       ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN sampled_inventory si ON si.inv_item_sk = i.i_item_sk
    LEFT JOIN union_keys uk       ON uk.key = cc.cc_call_center_sk
    CROSS JOIN (SELECT DISTINCT t_shift FROM time_dim LIMIT 5) AS td_small   -- small dimension cross‑joined
WHERE
    NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_amt > 100
    )
    AND td.t_am_pm = 'PM'
GROUP BY
    c.c_customer_id,
    i.i_product_name,
    td.t_shift,
    CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END
ORDER BY
    total_ws_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
