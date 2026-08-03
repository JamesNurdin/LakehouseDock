WITH agg_store_sales AS (
    SELECT
        ss_customer_sk,
        ss_sold_date_sk,
        ss_promo_sk,
        SUM(ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity > 0
    GROUP BY ss_customer_sk, ss_sold_date_sk, ss_promo_sk
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    d_sale.d_year,
    hd.hd_vehicle_count,
    ib.ib_upper_bound,
    p.p_promo_name,
    sm.sm_type,
    ws.ws_web_page_sk,
    hour_part,
    SUM(agg.total_net_paid) AS sum_net_paid,
    SUM(agg.sales_cnt) AS total_sales,
    COUNT(*) AS row_count
FROM agg_store_sales agg
JOIN customer c
    ON agg.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
    ON agg.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_sale
    ON agg.ss_sold_date_sk = d_sale.d_date_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
   AND ws.ws_sold_date_sk = d_sale.d_date_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
FULL OUTER JOIN call_center cc
    ON cc.cc_open_date_sk = d_sale.d_date_sk
FULL OUTER JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sale.d_date_sk
JOIN date_dim d_cccp
    ON COALESCE(cc.cc_open_date_sk, cp.cp_start_date_sk) = d_cccp.d_date_sk
CROSS JOIN UNNEST(split(COALESCE(cc.cc_hours, ''), ',')) AS u(hour_part)
WHERE
    d_sale.d_year = 2001
    AND ca.ca_state IN ('TX', 'UT')
    AND ib.ib_lower_bound >= 50000
    AND p.p_discount_active = 'Y'
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    d_sale.d_year,
    hd.hd_vehicle_count,
    ib.ib_upper_bound,
    p.p_promo_name,
    sm.sm_type,
    ws.ws_web_page_sk,
    hour_part
HAVING
    SUM(agg.total_net_paid) > 10000
    AND SUM(agg.sales_cnt) >= 5
ORDER BY sum_net_paid DESC
LIMIT 100
