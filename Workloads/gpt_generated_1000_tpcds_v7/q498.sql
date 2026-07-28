WITH
    d AS (
        SELECT *
        FROM tpcds.date_dim
        WHERE d_year = 2001
          AND d_moy = 8
          AND d_dow = 3
    ),
    p AS (
        SELECT *
        FROM tpcds.promotion
        WHERE p_discount_active = 'Y'
    ),
    ws AS (
        SELECT *
        FROM tpcds.web_sales
        WHERE ws_quantity > 2
          AND ws_ext_sales_price > 1000
    ),
    wsit AS (
        SELECT *
        FROM tpcds.web_site
        WHERE web_state = 'CA'
    ),
    w AS (
        SELECT *
        FROM tpcds.warehouse
        WHERE w_state = 'CA'
    ),
    cr AS (
        SELECT *
        FROM tpcds.catalog_returns
        WHERE cr_return_quantity > 0
    ),
    t AS (
        SELECT *
        FROM tpcds.time_dim
        WHERE t_hour BETWEEN 8 AND 12
    ),
    cc AS (
        SELECT *
        FROM tpcds.call_center
        WHERE cc_country = 'United States'
    ),
    cp AS (
        SELECT *
        FROM tpcds.catalog_page
        WHERE cp_type = 'A'
    ),
    r AS (
        SELECT *
        FROM tpcds.reason
        WHERE r_reason_desc LIKE '%damaged%'
    ),
    sr AS (
        SELECT *
        FROM tpcds.store_returns
        WHERE sr_return_quantity > 0
    ),
    cd AS (
        SELECT *
        FROM tpcds.customer_demographics
        WHERE cd_gender = 'M'
    ),
    hd AS (
        SELECT *
        FROM tpcds.household_demographics
        WHERE hd_buy_potential = '500-1000'
    ),
    ib AS (
        SELECT *
        FROM tpcds.income_band
        WHERE ib_upper_bound < 80000
    )
SELECT
    d.d_year,
    w.w_state,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_buy_potential,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(sr.sr_net_loss) AS avg_store_loss,
    MIN(ib.ib_lower_bound) AS min_income_lower,
    MAX(ib.ib_upper_bound) AS max_income_upper
FROM d
JOIN p ON p.p_start_date_sk = d.d_date_sk
JOIN ws ON ws.ws_promo_sk = p.p_promo_sk
JOIN wsit ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN r ON cr.cr_reason_sk = r.r_reason_sk
JOIN sr ON sr.sr_reason_sk = r.r_reason_sk
JOIN cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    d.d_year,
    w.w_state,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_buy_potential
LIMIT 100
