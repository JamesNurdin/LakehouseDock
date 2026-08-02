WITH base AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        s.s_state AS store_state,
        cc.cc_state AS call_center_state,
        w.w_state AS warehouse_state,
        p.p_promo_name AS p_promo_name,
        p.p_discount_active AS p_discount_active,
        t.t_hour AS t_hour,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cr.cr_net_loss AS cr_net_loss,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_net_loss AS wr_net_loss
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE s.s_state = 'CA'
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_quantity > 0
      AND cs.cs_quantity > 0
      AND ws.ws_quantity > 0
), aggregated AS (
    SELECT
        s_store_id,
        s_store_name,
        store_state,
        p_promo_name,
        SUM(ss_net_paid) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(cs_net_paid) AS total_catalog_sales,
        SUM(cs_net_profit) AS total_catalog_profit,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(sr_net_loss) AS total_store_returns_loss,
        SUM(cr_net_loss) AS total_catalog_returns_loss,
        SUM(wr_net_loss) AS total_web_returns_loss,
        (SUM(ss_net_profit) + SUM(cs_net_profit) + SUM(ws_net_profit)) AS total_profit
    FROM base
    GROUP BY s_store_id, s_store_name, store_state, p_promo_name
)
SELECT
    s_store_id,
    s_store_name,
    store_state,
    p_promo_name,
    total_store_sales,
    total_catalog_sales,
    total_web_sales,
    total_store_profit,
    total_catalog_profit,
    total_web_profit,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 100
