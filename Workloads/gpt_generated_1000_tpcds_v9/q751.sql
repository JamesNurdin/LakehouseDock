WITH sales_aggregated AS (
    SELECT
        d.d_year,
        ca.ca_state,
        c.c_customer_id,
        p.p_promo_id,
        sm.sm_type,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
    FROM store_sales ss
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year >= 2000
      AND p.p_channel_email = 'Y'
      AND hd.hd_buy_potential = '501-1000'
      AND ib.ib_lower_bound > 30000
      AND sm.sm_type = 'AIR'
    GROUP BY ROLLUP (d.d_year, ca.ca_state, c.c_customer_id, p.p_promo_id, sm.sm_type)
)
SELECT
    d_year,
    ca_state,
    c_customer_id,
    p_promo_id,
    sm_type,
    total_store_sales,
    total_web_sales,
    total_return_amount,
    total_store_profit,
    total_web_profit,
    (total_store_sales + total_web_sales) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (total_store_sales + total_web_sales) DESC) AS sales_rank,
    (SELECT MAX(ib_upper_bound) FROM income_band WHERE ib_lower_bound > 30000) AS max_income_upper_bound
FROM sales_aggregated
WHERE (total_store_sales + total_web_sales) > 100000
ORDER BY d_year, total_sales DESC
