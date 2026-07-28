WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_promo_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_sold_time_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity
    FROM catalog_sales
    WHERE cs_quantity > 1
    GROUP BY cs_item_sk, cs_promo_sk, cs_call_center_sk, cs_ship_mode_sk, cs_sold_time_sk
),
base AS (
    SELECT
        p.p_promo_id,
        cc.cc_division_name,
        i.i_brand,
        SUM(cs_agg.total_net_paid) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_web_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns
    FROM cs_agg
    JOIN item i               ON cs_agg.cs_item_sk = i.i_item_sk
    JOIN promotion p          ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc       ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm         ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td          ON cs_agg.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr   ON cs_agg.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r_cr          ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN time_dim td_cr       ON cr.cr_returned_time_sk = td_cr.t_time_sk
    LEFT JOIN store_returns sr     ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN customer c_sr        ON sr.sr_customer_sk = c_sr.c_customer_sk
    LEFT JOIN household_demographics hd_sr ON c_sr.c_current_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN income_band ib_sr    ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
    LEFT JOIN customer_address ca_sr ON c_sr.c_current_addr_sk = ca_sr.ca_address_sk
    LEFT JOIN reason r_sr          ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_sales ws         ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN web_site ws_site      ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN customer c_ws        ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    LEFT JOIN household_demographics hd_ws ON c_ws.c_current_hdemo_sk = hd_ws.hd_demo_sk
    LEFT JOIN income_band ib_ws    ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
    LEFT JOIN customer_address ca_ws ON c_ws.c_current_addr_sk = ca_ws.ca_address_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND p.p_channel_email = 'N'
      AND ws.ws_list_price BETWEEN 50 AND 300
      AND cs_agg.cs_sold_time_sk BETWEEN 1000 AND 2000
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_end_date <= DATE '2025-12-31'
    GROUP BY p.p_promo_id, cc.cc_division_name, i.i_brand
)
SELECT
    base.*,
    RANK() OVER (PARTITION BY base.cc_division_name ORDER BY base.total_sales DESC) AS sales_rank_by_division,
    CASE WHEN base.total_sales > 1000000 THEN 'High' ELSE 'Medium' END AS sales_category
FROM base
ORDER BY base.total_sales DESC
LIMIT 100
