WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_cnt,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_cnt,
        COUNT(sr.sr_ticket_number) AS total_returns,
        AVG(wp.wp_link_count) AS avg_page_links
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ca.ca_state = 'TX'
      AND wp.wp_type = 'general'
      AND wp.wp_rec_end_date > DATE '2000-01-01'
      AND wp.wp_rec_start_date < DATE '2001-01-01'
      AND ss.ss_net_paid_inc_tax > 100
      AND ws.ws_sales_price > 50
    GROUP BY p.p_promo_id, ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT
    p_promo_id,
    ib_lower_bound,
    ib_upper_bound,
    store_net_profit,
    web_net_profit,
    (store_net_profit + web_net_profit) AS total_profit,
    total_returns,
    avg_page_links,
    (store_net_profit + web_net_profit) / NULLIF(total_returns, 0) AS profit_per_return
FROM sales_agg
WHERE total_returns > 5
  AND (store_net_profit + web_net_profit) > 500
ORDER BY total_profit DESC
LIMIT 100
