WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_store_sk,
        cs.cs_net_profit,
        cs.cs_order_number,
        ws.ws_net_profit,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        w.w_county,
        p.p_discount_active,
        c.c_birth_year,
        hd.hd_vehicle_count,
        r.r_reason_desc
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
      AND hd.hd_vehicle_count >= 1
      AND s.s_state = 'CA'
      AND w.w_county = 'Fairfield County'
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc LIKE '%damaged%'
),
agg AS (
    SELECT
        s_store_id,
        s_store_name,
        s_state,
        SUM(ss_net_profit) AS store_sales_profit,
        SUM(cs_net_profit) AS catalog_sales_profit,
        SUM(ws_net_profit) AS web_sales_profit,
        SUM(ss_net_profit + cs_net_profit + ws_net_profit) AS total_profit
    FROM base
    GROUP BY s_store_id, s_store_name, s_state
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    store_sales_profit,
    catalog_sales_profit,
    web_sales_profit,
    total_profit,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 10
