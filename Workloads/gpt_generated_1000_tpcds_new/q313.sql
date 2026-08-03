WITH joined AS (
    SELECT
        ss.ss_ext_sales_price,
        ws.ws_ext_sales_price,
        cr.cr_return_amount,
        p_ss.p_cost,
        c.c_customer_sk,
        i.i_item_sk,
        i.i_brand,
        s.s_state,
        d_ss.d_year AS sold_year
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d_cr_return ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    JOIN time_dim t_cr_return ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    -- Additional optional joins (e.g., call_center dates) are omitted as they are not required for the analysis
)
SELECT
    u.s_state,
    u.i_brand,
    u.sold_year,
    SUM(u.ss_ext_sales_price)        AS total_store_sales,
    AVG(u.ws_ext_sales_price)        AS avg_web_sales,
    COUNT(DISTINCT u.c_customer_sk)  AS distinct_customers,
    COUNT(DISTINCT u.i_item_sk)      AS distinct_items,
    MIN(u.cr_return_amount)          AS min_return_amount,
    MAX(u.p_cost)                    AS max_promo_cost
FROM (
    SELECT * FROM joined
    WHERE sold_year = 2001
      AND i_brand   = 'Brand#12'
      AND s_state   = 'CA'
    UNION DISTINCT
    SELECT * FROM joined
    WHERE sold_year = 2002
      AND i_brand   = 'Brand#23'
      AND s_state   = 'TX'
) AS u
GROUP BY u.s_state, u.i_brand, u.sold_year
ORDER BY total_store_sales DESC
LIMIT 100
