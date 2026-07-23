WITH sales_data AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        wsite.web_site_id AS web_site_id,
        wsite.web_name AS web_name,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        p.p_promo_id AS p_promo_id,
        p.p_promo_name AS p_promo_name,
        d_ss.d_year AS d_year,
        d_ss.d_month_seq AS d_month_seq,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_net_loss AS wr_net_loss,
        cc.cc_name AS cc_name,
        r.r_reason_desc AS r_reason_desc,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        CASE
            WHEN ss.ss_net_profit > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_flag,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_profit DESC) AS store_sales_rank,
        RANK() OVER (PARTITION BY wsite.web_site_id ORDER BY ws.ws_net_profit DESC) AS web_site_profit_rank
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN store s_sr ON sr.sr_store_sk = s_sr.s_store_sk
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d_ws.d_date_sk
    LEFT JOIN date_dim d_ws_open ON wsite.web_open_date_sk = d_ws_open.d_date_sk
    WHERE d_ss.d_year = 2001
      AND s.s_state = 'CA'
      AND wsite.web_state = 'CA'
      AND i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 50000
      AND d_ws.d_month_seq BETWEEN 1 AND 12
)
SELECT
    s_store_id,
    s_store_name,
    web_site_id,
    web_name,
    i_item_id,
    i_product_name,
    p_promo_id,
    p_promo_name,
    d_year,
    d_month_seq,
    ss_net_paid,
    ss_net_profit,
    sr_net_loss,
    ws_net_paid,
    ws_net_profit,
    wr_net_loss,
    cc_name,
    r_reason_desc,
    ib_lower_bound,
    ib_upper_bound,
    profit_flag,
    store_sales_rank,
    web_site_profit_rank
FROM sales_data
ORDER BY store_sales_rank, web_site_profit_rank
LIMIT 100
