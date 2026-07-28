WITH base AS (
    SELECT
        d.d_year,
        p.p_promo_id,
        p.p_promo_name,
        ss.ss_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss
    FROM date_dim d
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN web_site sit
        ON sit.web_open_date_sk = d.d_date_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND p.p_channel_dmail = 'Y'
      AND p.p_channel_press = 'N'
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND w.w_country = 'United States'
      AND ss.ss_quantity > 5
),
agg AS (
    SELECT
        d_year,
        p_promo_id,
        p_promo_name,
        SUM(COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(sr_net_loss, 0) - COALESCE(wr_net_loss, 0)) AS total_profit
    FROM base
    GROUP BY d_year, p_promo_id, p_promo_name
)
SELECT
    d_year,
    p_promo_id,
    p_promo_name,
    total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
    SUM(total_profit) OVER (PARTITION BY d_year ORDER BY total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM agg
ORDER BY d_year, profit_rank
