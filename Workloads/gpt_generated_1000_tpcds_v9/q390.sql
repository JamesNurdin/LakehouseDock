WITH
store_fact AS (
    SELECT
        ss.ss_ticket_number AS ss_ticket_number,
        ss.ss_sold_date_sk AS ss_sold_date_sk,
        ss.ss_sold_time_sk AS ss_sold_time_sk,
        ss.ss_store_sk AS ss_store_sk,
        ss.ss_promo_sk AS ss_promo_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        s.s_store_name AS s_store_name,
        s.s_market_id AS s_market_id,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        t.t_hour AS t_hour,
        p.p_promo_name AS p_promo_name,
        hd.hd_income_band_sk AS hd_income_band_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND s.s_market_id IN (1, 5)
),
store_return_fact AS (
    SELECT
        sr.sr_ticket_number AS sr_ticket_number,
        sr.sr_returned_date_sk AS sr_returned_date_sk,
        sr.sr_return_quantity AS sr_return_quantity,
        sr.sr_return_amt AS sr_return_amt,
        r.r_reason_desc AS r_reason_desc,
        d.d_year AS return_year,
        t.t_hour AS return_hour
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
),
catalog_fact AS (
    SELECT
        cs.cs_order_number AS cs_order_number,
        cs.cs_sold_date_sk AS cs_sold_date_sk,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cc.cc_name AS cc_name,
        p.p_promo_name AS p_promo_name,
        sm.sm_type AS sm_type,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        hd.hd_income_band_sk AS hd_income_band_sk,
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_promo_sk AS cs_promo_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND cc.cc_name = 'Metro Call Center'
),
catalog_return_fact AS (
    SELECT
        cr.cr_order_number AS cr_order_number,
        cr.cr_returned_date_sk AS cr_returned_date_sk,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        r.r_reason_desc AS r_reason_desc,
        d.d_year AS return_year,
        sm.sm_type AS return_ship_mode,
        cc.cc_name AS cc_name
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_fact AS (
    SELECT
        ws.ws_order_number AS ws_order_number,
        ws.ws_sold_date_sk AS ws_sold_date_sk,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        wp.wp_url AS wp_url,
        wsite.web_county AS web_county,
        p.p_promo_name AS p_promo_name,
        sm.sm_type AS sm_type,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        hd.hd_income_band_sk AS hd_income_band_sk,
        ws.ws_item_sk AS ws_item_sk,
        ws.ws_promo_sk AS ws_promo_sk
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND wsite.web_county = 'Pennington County'
      AND p.p_promo_name LIKE '%Discount%'
),
web_return_fact AS (
    SELECT
        wr.wr_order_number AS wr_order_number,
        wr.wr_returned_date_sk AS wr_returned_date_sk,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_return_amt AS wr_return_amt,
        r.r_reason_desc AS r_reason_desc,
        d.d_year AS return_year
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
aggregated AS (
    SELECT
        sf.s_store_name,
        sf.s_market_id,
        sf.d_year,
        sf.d_month_seq,
        sf.p_promo_name,
        SUM(sf.ss_net_paid) AS total_store_net_paid,
        SUM(cf.cs_net_paid) AS total_catalog_net_paid,
        SUM(wf.ws_net_paid) AS total_web_net_paid,
        COUNT(DISTINCT sf.s_store_name) AS store_count,
        AVG(
            (SELECT AVG(cs.cs_ext_discount_amt)
             FROM catalog_sales cs
             WHERE cs.cs_promo_sk = sf.ss_promo_sk)
        ) AS avg_catalog_discount_for_store_promo
    FROM store_fact sf
    LEFT JOIN catalog_fact cf
        ON cf.cs_sold_date_sk = sf.ss_sold_date_sk
       AND cf.p_promo_name = sf.p_promo_name
    LEFT JOIN web_fact wf
        ON wf.ws_sold_date_sk = sf.ss_sold_date_sk
       AND wf.p_promo_name = sf.p_promo_name
    LEFT JOIN store_return_fact srf
        ON srf.sr_ticket_number = sf.ss_ticket_number
    LEFT JOIN catalog_return_fact crf
        ON crf.cr_order_number = cf.cs_order_number
    LEFT JOIN web_return_fact wrf
        ON wrf.wr_order_number = wf.ws_order_number
    GROUP BY
        sf.s_store_name,
        sf.s_market_id,
        sf.d_year,
        sf.d_month_seq,
        sf.p_promo_name
)
SELECT
    a.s_store_name,
    a.s_market_id,
    a.d_year,
    a.d_month_seq,
    a.p_promo_name,
    a.total_store_net_paid,
    a.total_catalog_net_paid,
    a.total_web_net_paid,
    a.store_count,
    a.avg_catalog_discount_for_store_promo,
    SUM(a.total_store_net_paid) OVER (PARTITION BY a.s_market_id ORDER BY a.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_store_net_paid,
    ROW_NUMBER() OVER (PARTITION BY a.s_market_id ORDER BY a.total_store_net_paid DESC) AS market_store_rank
FROM aggregated a
ORDER BY a.total_store_net_paid DESC, a.total_catalog_net_paid DESC
LIMIT 100
