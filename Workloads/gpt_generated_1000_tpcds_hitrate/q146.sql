WITH promo_perf AS (
    SELECT ss_promo_sk,
           AVG(ss_net_profit) AS avg_net_profit
    FROM   store_sales
    GROUP BY ss_promo_sk
    HAVING AVG(ss_net_profit) > 1000
)
SELECT
    ca_ss.ca_state                                     AS customer_state,
    sm.sm_code                                         AS ship_mode_code,
    p.p_promo_name                                     AS promotion_name,
    r.r_reason_desc                                    AS return_reason,
    ib.ib_lower_bound                                  AS income_lower_bound,
    COUNT(DISTINCT ss.ss_ticket_number)                AS store_sales_txn_cnt,
    SUM(ss.ss_net_profit)                              AS store_total_net_profit,
    SUM(ws.ws_net_profit)                              AS web_total_net_profit,
    SUM(wr.wr_net_loss)                                AS web_return_total_net_loss,
    AVG(ss.ss_quantity)                               AS avg_store_quantity
FROM   store_sales ss
JOIN   promotion p
       ON ss.ss_promo_sk = p.p_promo_sk
JOIN   household_demographics hd_ss
       ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN   income_band ib
       ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
JOIN   customer_address ca_ss
       ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN   web_sales ws
       ON ws.ws_order_number = ss.ss_ticket_number
      AND ws.ws_item_sk = ss.ss_item_sk
JOIN   promotion p_ws
       ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN   household_demographics hd_ws
       ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
JOIN   customer_address ca_ws
       ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
JOIN   ship_mode sm
       ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN   web_page wp
       ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN   web_returns wr
       ON wr.wr_order_number = ws.ws_order_number
      AND wr.wr_item_sk = ws.ws_item_sk
JOIN   reason r
       ON wr.wr_reason_sk = r.r_reason_sk
JOIN   web_page wp_ret
       ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
JOIN   household_demographics hd_ret_ref
       ON wr.wr_refunded_hdemo_sk = hd_ret_ref.hd_demo_sk
JOIN   customer_address ca_ret_ref
       ON wr.wr_refunded_addr_sk = ca_ret_ref.ca_address_sk
WHERE  ca_ss.ca_state = 'CA'
  AND  sm.sm_code = 'AIR'
  AND  ib.ib_lower_bound >= 100000
  AND  EXISTS (SELECT 1 FROM promo_perf pp WHERE pp.ss_promo_sk = p.p_promo_sk)
GROUP BY
    ca_ss.ca_state,
    sm.sm_code,
    p.p_promo_name,
    r.r_reason_desc,
    ib.ib_lower_bound
ORDER BY
    store_total_net_profit DESC
LIMIT 100
