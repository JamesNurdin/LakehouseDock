WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ss_net_profit) AS total_store_profit
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    p.p_promo_name,
    sm.sm_type,
    c.c_first_name,
    c.c_last_name,
    total_store_sales,
    total_store_profit,
    sr.sr_return_amt,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY total_store_sales DESC) AS sales_rank
FROM ss_agg
JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
JOIN date_dim d
    ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
    AND cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
WHERE
    d.d_year = 2000
    AND i.i_brand = 'BrandX'
    AND p.p_channel_press = 'N'
    AND ib.ib_lower_bound >= 10000
    AND c.c_preferred_cust_flag = 'Y'
    AND cs.cs_quantity > 1
LIMIT 100
