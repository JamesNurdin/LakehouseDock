WITH ss AS (
    SELECT
        s.s_store_id,
        d.d_year,
        p.p_promo_name,
        ca.ca_state,
        hd.hd_buy_potential,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND s.s_tax_percentage > 0.05
      AND p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
      AND hd.hd_buy_potential <> 'Unknown'
    GROUP BY s.s_store_id, d.d_year, p.p_promo_name, ca.ca_state, hd.hd_buy_potential
),
ws AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        sm.sm_type,
        wp.wp_web_page_id,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND (wp.wp_type = 'content' OR wp.wp_type IS NULL)
    GROUP BY d.d_year, p.p_promo_name, sm.sm_type, wp.wp_web_page_id
),
wr AS (
    SELECT
        d.d_year,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year
)
SELECT
    ss.s_store_id,
    ss.d_year,
    ss.p_promo_name,
    ss.ca_state,
    ss.hd_buy_potential,
    ss.store_sales,
    ss.store_profit,
    ws.web_sales,
    ws.web_profit,
    wr.total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY ss.d_year ORDER BY (ss.store_profit + ws.web_profit) DESC) AS profit_rank
FROM ss
LEFT JOIN ws ON ss.d_year = ws.d_year AND ss.p_promo_name = ws.p_promo_name
LEFT JOIN wr ON ss.d_year = wr.d_year
ORDER BY profit_rank
LIMIT 100
