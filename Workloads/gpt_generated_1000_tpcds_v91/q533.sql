WITH base AS (
    SELECT 
        sr.sr_return_time_sk,
        s.s_store_sk AS s_store_sk,
        s.s_store_name AS s_store_name,
        cc.cc_call_center_sk AS cc_call_center_sk,
        cc.cc_name AS cc_name,
        cr.cr_return_amount AS cr_return_amount,
        ws.ws_sold_time_sk,
        ws.ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        t.t_hour AS t_hour,
        c.c_customer_sk AS c_customer_sk,
        cd.cd_demo_sk AS cd_demo_sk,
        hd.hd_demo_sk AS hd_demo_sk,
        ib.ib_income_band_sk AS ib_income_band_sk,
        ib.ib_upper_bound AS ib_upper_bound,
        p.p_promo_sk AS p_promo_sk,
        p.p_promo_name AS p_promo_name,
        wp.wp_web_page_sk AS wp_web_page_sk,
        wp.wp_url AS wp_url,
        wr.wr_net_loss AS wr_net_loss,
        sr.sr_net_loss AS sr_net_loss,
        cc.cc_rec_start_date AS cc_rec_start_date,
        s.s_state AS s_state,
        ws.ws_web_site_sk AS ws_web_site_sk
    FROM store_returns sr
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE 
        cc.cc_rec_start_date >= DATE '2000-01-01'
        AND s.s_state = 'TX'
        AND t.t_hour BETWEEN 9 AND 17
        AND ws.ws_quantity >= 2
        AND EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_order_number = ws.ws_order_number
              AND wr2.wr_net_loss > 0
        )
),
agg AS (
    SELECT 
        s_store_sk,
        s_store_name,
        cc_call_center_sk,
        cc_name,
        p_promo_sk,
        p_promo_name,
        wp_web_page_sk,
        wp_url,
        t_hour,
        ws_web_site_sk,
        COUNT(DISTINCT c_customer_sk) AS unique_customers,
        SUM(sr_net_loss) AS total_store_return_net_loss,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(ws_net_profit) AS total_sales_net_profit,
        AVG(ws_quantity) AS avg_quantity,
        SUM(wr_net_loss) AS total_web_return_net_loss
    FROM base
    GROUP BY 
        s_store_sk,
        s_store_name,
        cc_call_center_sk,
        cc_name,
        p_promo_sk,
        p_promo_name,
        wp_web_page_sk,
        wp_url,
        t_hour,
        ws_web_site_sk
)
SELECT 
    s_store_sk,
    s_store_name,
    cc_call_center_sk,
    cc_name,
    p_promo_sk,
    p_promo_name,
    wp_web_page_sk,
    wp_url,
    t_hour,
    unique_customers,
    total_store_return_net_loss,
    total_catalog_return_amount,
    total_sales_net_profit,
    avg_quantity,
    total_web_return_net_loss,
    (
        SELECT SUM(ws2.ws_net_profit)
        FROM web_sales ws2
        WHERE ws2.ws_web_site_sk = agg.ws_web_site_sk
    ) AS site_total_net_profit,
    SUM(total_store_return_net_loss) OVER (PARTITION BY s_store_sk ORDER BY t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_store_return_net_loss,
    LAG(total_sales_net_profit) OVER (PARTITION BY s_store_sk ORDER BY t_hour) AS lag_sales_net_profit
FROM agg
ORDER BY total_sales_net_profit DESC
LIMIT 100
