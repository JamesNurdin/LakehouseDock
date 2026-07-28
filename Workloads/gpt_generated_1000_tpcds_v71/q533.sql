WITH joined_data AS (
    SELECT
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        d.d_year AS d_year,
        p.p_promo_name AS p_promo_name,
        p.p_channel_radio AS p_channel_radio,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        cr.cr_return_amount AS cr_return_amount,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        wr.wr_return_amt AS wr_return_amt,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_channel_radio = 'N'
      AND s.s_state = 'CA'
      AND ss.ss_net_profit > 0
),
aggregated AS (
    SELECT
        s_store_name,
        d_year,
        p_promo_name,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(cr_return_amount) AS total_catalog_returns,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(wr_return_amt) AS total_web_returns,
        SUM(ss_net_profit + ws_net_profit) AS total_net_profit
    FROM joined_data
    GROUP BY s_store_name, d_year, p_promo_name
)
SELECT
    s_store_name,
    d_year,
    p_promo_name,
    total_store_sales,
    total_catalog_returns,
    total_web_sales,
    total_web_returns,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY d_year, profit_rank
LIMIT 100
