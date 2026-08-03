WITH
    cs_agg AS (
        SELECT
            cs.cs_catalog_page_sk,
            cs.cs_sold_date_sk,
            cs.cs_call_center_sk,
            cs.cs_promo_sk,
            cs.cs_ship_mode_sk,
            SUM(cs.cs_net_paid)      AS total_net_paid,
            SUM(cs.cs_quantity)      AS total_quantity,
            COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
        FROM catalog_sales cs
        GROUP BY
            cs.cs_catalog_page_sk,
            cs.cs_sold_date_sk,
            cs.cs_call_center_sk,
            cs.cs_promo_sk,
            cs.cs_ship_mode_sk
    ),
    order_not_returned AS (
        SELECT cs_order_number FROM catalog_sales
        EXCEPT
        SELECT cr_order_number FROM catalog_returns
    )
SELECT
    cc.cc_division,
    dd.d_year,
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type,
    ib.ib_upper_bound,
    SUM(cs_agg.total_net_paid)               AS sum_net_paid,
    AVG(cs_agg.total_quantity)               AS avg_quantity,
    COUNT(DISTINCT cs_agg.cs_catalog_page_sk) AS distinct_pages,
    COUNT(DISTINCT cs_agg.cs_sold_date_sk)    AS distinct_sold_dates,
    max_page_profit.max_net_profit,
    COUNT(DISTINCT cd_store.cd_demo_sk)       AS distinct_store_customer_demo,
    COUNT(DISTINCT cd_web_refunded.cd_demo_sk) AS distinct_web_customer_demo,
    (SELECT COUNT(*) FROM order_not_returned) AS orders_not_returned_cnt
FROM cs_agg
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dd
    ON cs_agg.cs_sold_date_sk = dd.d_date_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = dd.d_date_sk
JOIN customer_demographics cd_store
    ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
JOIN household_demographics hd_store
    ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
JOIN income_band ib
    ON hd_store.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dd.d_date_sk
JOIN customer_demographics cd_web_refunded
    ON wr.wr_refunded_cdemo_sk = cd_web_refunded.cd_demo_sk
JOIN household_demographics hd_web_refunded
    ON wr.wr_refunded_hdemo_sk = hd_web_refunded.hd_demo_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = dd.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = dd.d_date_sk
CROSS JOIN LATERAL (
    SELECT MAX(cs.cs_net_paid) AS max_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_catalog_page_sk = cs_agg.cs_catalog_page_sk
) AS max_page_profit
WHERE dd.d_year = 2001
  AND cc.cc_division = 2
  AND ib.ib_upper_bound = 150000
  AND sm.sm_type = 'AIR'
  AND p.p_discount_active = 'Y'
  AND cs_agg.cs_catalog_page_sk NOT IN (
        SELECT cp2.cp_catalog_page_sk
        FROM catalog_page cp2
        WHERE cp2.cp_department = 'Electronics'
    )
GROUP BY
    cc.cc_division,
    dd.d_year,
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type,
    ib.ib_upper_bound,
    max_page_profit.max_net_profit
HAVING SUM(cs_agg.total_net_paid) > 0
ORDER BY sum_net_paid DESC
LIMIT 100
