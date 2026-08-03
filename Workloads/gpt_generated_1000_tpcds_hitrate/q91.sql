SELECT
    s.s_state,
    cd.cd_credit_rating,
    ib.ib_income_band_sk,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
FROM
    store_sales ss
    JOIN time_dim td1 ON ss.ss_sold_time_sk = td1.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    -- Web sales and related dimensions
    JOIN web_sales ws ON ws.ws_sold_time_sk = td1.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    -- Catalog returns and related dimensions
    JOIN catalog_returns cr ON cr.cr_returned_time_sk = td1.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
WHERE
    s.s_state = 'CA'
    AND cd.cd_credit_rating = 'Good'
    AND p.p_discount_active = 'Y'
    AND ib.ib_upper_bound > 50000
    AND td1.t_hour BETWEEN 9 AND 17
GROUP BY
    s.s_state,
    cd.cd_credit_rating,
    ib.ib_income_band_sk
ORDER BY
    total_store_sales DESC
LIMIT 100
