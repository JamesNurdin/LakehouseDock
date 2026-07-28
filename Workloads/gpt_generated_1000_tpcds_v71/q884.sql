WITH base AS (
    SELECT
        s.s_store_id,
        d1.d_year,
        ss.ss_net_profit               AS store_net_profit,
        cs.cs_net_profit               AS catalog_net_profit,
        ws.ws_net_profit               AS web_net_profit,
        sr.sr_net_loss                 AS store_return_loss,
        p.p_promo_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state,
        sm.sm_type                     AS ship_mode_type,
        w.w_warehouse_name,
        cc.cc_name                     AS call_center_name,
        ws_site.web_name               AS web_site_name,
        (ss.ss_net_profit + cs.cs_net_profit + ws.ws_net_profit) AS total_profit
    FROM store_sales          ss
    JOIN date_dim            d1        ON ss.ss_sold_date_sk   = d1.d_date_sk
    JOIN store               s         ON ss.ss_store_sk       = s.s_store_sk
    JOIN promotion           p         ON ss.ss_promo_sk       = p.p_promo_sk
    JOIN household_demographics hd      ON ss.ss_hdemo_sk      = hd.hd_demo_sk
    JOIN income_band         ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address    ca        ON ss.ss_addr_sk        = ca.ca_address_sk
    LEFT JOIN store_returns sr
           ON sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_store_sk      = s.s_store_sk
          AND sr.sr_returned_date_sk = d1.d_date_sk
    JOIN catalog_sales      cs        ON cs.cs_sold_date_sk   = d1.d_date_sk
    JOIN call_center        cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode          sm        ON cs.cs_ship_mode_sk    = sm.sm_ship_mode_sk
    JOIN warehouse          w         ON cs.cs_warehouse_sk    = w.w_warehouse_sk
    JOIN web_sales          ws        ON ws.ws_sold_date_sk   = d1.d_date_sk
    JOIN web_site           ws_site   ON ws.ws_web_site_sk    = ws_site.web_site_sk
    -- additional joins to satisfy ship_mode and warehouse from web_sales
    JOIN ship_mode          sm_ws     ON ws.ws_ship_mode_sk   = sm_ws.sm_ship_mode_sk
    JOIN warehouse          w_ws      ON ws.ws_warehouse_sk   = w_ws.w_warehouse_sk
    WHERE
        d1.d_year = 2001
        AND ib.ib_lower_bound >= 100000
        AND ca.ca_state = 'CA'
        AND EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_returned_date_sk = d1.d_date_sk
              AND wr.wr_return_amt > 100
        )
)
SELECT
    b.s_store_id,
    AVG(b.total_profit)          AS avg_total_profit,
    SUM(b.store_return_loss)    AS total_store_return_loss
FROM base b
GROUP BY b.s_store_id
HAVING AVG(b.total_profit) > 5000
ORDER BY avg_total_profit DESC
LIMIT 100
