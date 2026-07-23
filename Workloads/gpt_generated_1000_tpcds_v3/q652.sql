WITH catalog_sales_agg AS (
    SELECT
        cs_bill_customer_sk,
        cs_item_sk,
        cs_sold_time_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        SUM(cs_net_profit) AS cat_total_net_profit,
        SUM(cs_quantity) AS cat_total_quantity
    FROM catalog_sales
    WHERE cs_net_profit > 0
    GROUP BY cs_bill_customer_sk, cs_item_sk, cs_sold_time_sk, cs_promo_sk, cs_call_center_sk, cs_ship_mode_sk
)
SELECT
    c.c_customer_id,
    i.i_item_id,
    i.i_category,
    t.t_hour,
    cc.cc_name AS call_center_name,
    sm.sm_type AS ship_mode_type,
    p_ss.p_promo_name AS store_promo_name,
    p_cs.p_promo_name AS catalog_promo_name,
    p_ws.p_promo_name AS web_promo_name,
    ss.ss_net_profit AS store_net_profit,
    ca.cat_total_net_profit,
    ws.ws_net_profit AS web_net_profit,
    (COALESCE(ss.ss_net_profit, 0) + COALESCE(ca.cat_total_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
    RANK() OVER (
        PARTITION BY i.i_category
        ORDER BY (COALESCE(ss.ss_net_profit, 0) + COALESCE(ca.cat_total_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) DESC
    ) AS category_rank,
    ROW_NUMBER() OVER (
        ORDER BY (COALESCE(ss.ss_net_profit, 0) + COALESCE(ca.cat_total_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) DESC
    ) AS overall_rank
FROM catalog_sales_agg ca
JOIN store_sales ss
    ON ss.ss_customer_sk = ca.cs_bill_customer_sk
   AND ss.ss_item_sk = ca.cs_item_sk
   AND ss.ss_sold_time_sk = ca.cs_sold_time_sk
   AND ss.ss_promo_sk = ca.cs_promo_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = ca.cs_bill_customer_sk
   AND ws.ws_item_sk = ca.cs_item_sk
   AND ws.ws_sold_time_sk = ca.cs_sold_time_sk
   AND ws.ws_promo_sk = ca.cs_promo_sk
JOIN customer c
    ON c.c_customer_sk = ca.cs_bill_customer_sk
JOIN customer_address ca_addr
    ON ca_addr.ca_address_sk = ss.ss_addr_sk
JOIN item i
    ON i.i_item_sk = ca.cs_item_sk
JOIN time_dim t
    ON t.t_time_sk = ca.cs_sold_time_sk
JOIN promotion p_ss
    ON p_ss.p_promo_sk = ss.ss_promo_sk
JOIN promotion p_cs
    ON p_cs.p_promo_sk = ca.cs_promo_sk
   AND p_cs.p_item_sk = i.i_item_sk
JOIN promotion p_ws
    ON p_ws.p_promo_sk = ws.ws_promo_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = ca.cs_call_center_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = ca.cs_ship_mode_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
   AND wp.wp_customer_sk = c.c_customer_sk
WHERE
    cc.cc_state = 'CA'
    AND i.i_category = 'Sports'
    AND p_ss.p_channel_radio = 'Y'
    AND ca_addr.ca_state = 'TX'
    AND t.t_hour BETWEEN 9 AND 17
    AND p_cs.p_discount_active = 'Y'
    AND ss.ss_ext_tax > 10
    AND ws.ws_quantity >= 2
ORDER BY
    total_net_profit DESC,
    c.c_customer_id
LIMIT 100
