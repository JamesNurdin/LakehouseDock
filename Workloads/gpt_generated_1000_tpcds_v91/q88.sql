SELECT
    cs.cs_order_number,
    sd.d_date AS sold_date,
    rd.d_date AS return_date,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    hd.hd_income_band_sk,
    p.p_promo_name,
    sm.sm_carrier,
    cs.cs_list_price,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_paid,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discount' ELSE 'No Discount' END AS promo_discount_flag,
    COALESCE(ws.web_name, 'No Web Site') AS web_site_name,
    ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY cs.cs_net_paid DESC) AS row_num_by_year
FROM
    catalog_sales cs
    JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim cd ON cc.cc_open_date_sk = cd.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = cd.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN date_dim rd ON sr.sr_returned_date_sk = rd.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    sd.d_year = 2000
    AND cs.cs_list_price > 100.00
    AND cs.cs_quantity >= 2
    AND sm.sm_carrier IN ('DIAMOND', 'AIRBORNE')
    AND p.p_discount_active = 'Y'
    AND r.r_reason_desc NOT LIKE '%return%'
ORDER BY
    row_num_by_year
LIMIT 100
