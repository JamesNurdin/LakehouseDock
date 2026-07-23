WITH per_store AS (
    SELECT
        s.s_store_id,
        ca.ca_state,
        p.p_promo_id,
        sm.sm_ship_mode_id,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ss.ss_net_profit) AS store_profit_total,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS web_sales_total,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS web_profit_total,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS returns_total,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE WHEN COUNT(DISTINCT ss.ss_ticket_number) = 0 THEN 0
             ELSE SUM(ss.ss_ext_sales_price) / COUNT(DISTINCT ss.ss_ticket_number)
        END AS avg_sales_per_ticket
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_addr_sk = ca.ca_address_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE s.s_division_name = 'Unknown'
      AND s.s_market_id IN (2, 5, 10)
      AND p.p_channel_dmail = 'Y'
      AND p.p_channel_radio = 'N'
    GROUP BY
        s.s_store_id,
        ca.ca_state,
        p.p_promo_id,
        sm.sm_ship_mode_id
)
SELECT
    ca_state,
    COUNT(DISTINCT s_store_id) AS num_stores,
    AVG(store_sales_total) AS avg_store_sales,
    AVG(store_profit_total) AS avg_store_profit,
    AVG(web_sales_total) AS avg_web_sales,
    AVG(web_profit_total) AS avg_web_profit,
    SUM(returns_total) AS total_returns,
    AVG(avg_sales_per_ticket) AS avg_sales_per_ticket_state,
    AVG(distinct_tickets) AS avg_distinct_tickets
FROM per_store
WHERE store_profit_total > 0
GROUP BY ca_state
HAVING COUNT(DISTINCT s_store_id) >= 3
ORDER BY avg_store_profit DESC
LIMIT 20
