WITH sales_filtered AS (
    SELECT
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_bill_hdemo_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    p.p_promo_name,
    sm.sm_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(sf.ws_ext_sales_price) AS total_sales,
    SUM(sf.ws_ext_discount_amt) AS total_discount,
    AVG(sf.ws_ext_discount_amt) AS avg_discount,
    COUNT(*) AS num_sales
FROM sales_filtered sf
JOIN tpcds.promotion p ON sf.ws_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm ON sf.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.household_demographics hd ON sf.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY p.p_promo_name, sm.sm_type, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
