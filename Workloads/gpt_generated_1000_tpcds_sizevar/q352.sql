WITH
    ss_agg AS (
        SELECT
            ss_store_sk,
            ss_sold_time_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            ss_item_sk,
            ss_promo_sk,
            SUM(ss_net_paid) AS store_total_net_paid
        FROM store_sales
        GROUP BY ss_store_sk, ss_sold_time_sk, ss_cdemo_sk, ss_hdemo_sk, ss_item_sk, ss_promo_sk
    ),
    cs_agg AS (
        SELECT
            cs_sold_time_sk,
            cs_call_center_sk,
            cs_item_sk,
            cs_promo_sk,
            cs_bill_customer_sk,
            SUM(cs_net_paid) AS catalog_total_net_paid
        FROM catalog_sales
        GROUP BY cs_sold_time_sk, cs_call_center_sk, cs_item_sk, cs_promo_sk, cs_bill_customer_sk
    ),
    common_stores AS (
        SELECT ss_store_sk FROM store_sales
        INTERSECT
        SELECT s_store_sk FROM store
    )
SELECT
    s.s_store_name,
    td.t_hour,
    cd.cd_gender,
    hd.hd_vehicle_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    i.i_brand,
    p.p_promo_name,
    cc.cc_name AS call_center_name,
    c.c_first_name,
    c.c_last_name,
    ss_agg.store_total_net_paid,
    cs_agg.catalog_total_net_paid,
    (ss_agg.store_total_net_paid + cs_agg.catalog_total_net_paid) AS combined_total,
    CASE
        WHEN ib.ib_upper_bound > 80000 THEN 'HIGH_INCOME'
        ELSE 'LOW_INCOME'
    END AS income_category
FROM
    ss_agg
FULL OUTER JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
LEFT JOIN common_stores cs_int
    ON s.s_store_sk = cs_int.ss_store_sk
LEFT JOIN time_dim td
    ON ss_agg.ss_sold_time_sk = td.t_time_sk
LEFT JOIN customer_demographics cd
    ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
LEFT JOIN promotion p
    ON ss_agg.ss_promo_sk = p.p_promo_sk
LEFT JOIN cs_agg
    ON td.t_time_sk = cs_agg.cs_sold_time_sk
LEFT JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN customer c
    ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
WHERE
    td.t_hour BETWEEN 9 AND 17
    AND s.s_state = 'CA'
    AND ib.ib_lower_bound >= 60001
    AND cs_int.ss_store_sk IS NOT NULL
ORDER BY
    combined_total DESC,
    s.s_store_name
LIMIT 100
