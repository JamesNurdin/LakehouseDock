WITH cs_agg AS (
    SELECT
        cs_bill_customer_sk,
        cs_sold_date_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_promo_sk,
        cs_ship_mode_sk,
        SUM(cs_net_paid)        AS total_net_paid,
        SUM(cs_quantity)        AS total_qty
    FROM tpcds.catalog_sales
    WHERE cs_quantity > 1
    GROUP BY
        cs_bill_customer_sk,
        cs_sold_date_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_promo_sk,
        cs_ship_mode_sk
),
ws_agg AS (
    SELECT
        ws_bill_customer_sk,
        ws_sold_date_sk,
        ws_web_page_sk,
        ws_web_site_sk,
        ws_promo_sk,
        ws_ship_mode_sk,
        SUM(ws_net_paid)        AS total_net_paid,
        SUM(ws_quantity)        AS total_qty
    FROM tpcds.web_sales
    WHERE ws_quantity > 1
    GROUP BY
        ws_bill_customer_sk,
        ws_sold_date_sk,
        ws_web_page_sk,
        ws_web_site_sk,
        ws_promo_sk,
        ws_ship_mode_sk
),
sr_sampled AS (
    SELECT *
    FROM tpcds.store_returns
    TABLESAMPLE BERNOULLI (10)
)
SELECT *
FROM (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_type,
        td.t_hour,
        SUM(cs_agg.total_net_paid)                        AS sum_catalog_net,
        SUM(ws_agg.total_net_paid)                        AS sum_web_net,
        SUM(sr_sampled.sr_return_amt)                    AS sum_return_amt,
        COUNT(*)                                          AS cnt_rows,
        RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs_agg.total_net_paid) DESC) AS dept_rank
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN cs_agg ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN ws_agg ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we ON ws_agg.ws_web_site_sk = we.web_site_sk
    JOIN sr_sampled ON sr_sampled.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim td ON sr_sampled.sr_return_time_sk = td.t_time_sk
    WHERE cc.cc_country = 'United States'
      AND cp.cp_department = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
    GROUP BY CUBE (
        c.c_customer_id,
        cp.cp_department,
        ib.ib_lower_bound,
        cd.cd_gender,
        hd.hd_income_band_sk,
        cc.cc_name,
        sm.sm_type,
        td.t_hour,
        p.p_promo_name,
        ib.ib_upper_bound
    )
) a
UNION DISTINCT
SELECT *
FROM (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_type,
        td.t_hour,
        SUM(cs_agg.total_net_paid) * 0.9                        AS sum_catalog_net,
        SUM(ws_agg.total_net_paid) * 0.9                        AS sum_web_net,
        SUM(sr_sampled.sr_return_amt) * 0.9                    AS sum_return_amt,
        COUNT(*)                                                AS cnt_rows,
        RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs_agg.total_net_paid) DESC) AS dept_rank
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN cs_agg ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN ws_agg ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we ON ws_agg.ws_web_site_sk = we.web_site_sk
    JOIN sr_sampled ON sr_sampled.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim td ON sr_sampled.sr_return_time_sk = td.t_time_sk
    WHERE cc.cc_country = 'United States'
      AND cp.cp_department = 'Electronics'
      AND p.p_discount_active = 'N'
      AND td.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
    GROUP BY CUBE (
        c.c_customer_id,
        cp.cp_department,
        ib.ib_lower_bound,
        cd.cd_gender,
        hd.hd_income_band_sk,
        cc.cc_name,
        sm.sm_type,
        td.t_hour,
        p.p_promo_name,
        ib.ib_upper_bound
    )
) b
EXCEPT
SELECT *
FROM (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        sm.sm_type,
        td.t_hour,
        SUM(cs_agg.total_net_paid)                        AS sum_catalog_net,
        SUM(ws_agg.total_net_paid)                        AS sum_web_net,
        SUM(sr_sampled.sr_return_amt)                    AS sum_return_amt,
        COUNT(*)                                          AS cnt_rows,
        RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs_agg.total_net_paid) DESC) AS dept_rank
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN cs_agg ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.call_center cc ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.promotion p ON cs_agg.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN ws_agg ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we ON ws_agg.ws_web_site_sk = we.web_site_sk
    JOIN sr_sampled ON sr_sampled.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.time_dim td ON sr_sampled.sr_return_time_sk = td.t_time_sk
    WHERE cc.cc_country = 'United States'
      AND cp.cp_department = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND td.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
    GROUP BY CUBE (
        c.c_customer_id,
        cp.cp_department,
        ib.ib_lower_bound,
        cd.cd_gender,
        hd.hd_income_band_sk,
        cc.cc_name,
        sm.sm_type,
        td.t_hour,
        p.p_promo_name,
        ib.ib_upper_bound
    )
) c
ORDER BY sum_catalog_net DESC
LIMIT 100
