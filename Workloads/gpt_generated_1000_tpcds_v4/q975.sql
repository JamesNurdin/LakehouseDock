WITH catalog_return_agg AS (
    SELECT
        cr.cr_reason_sk,
        cr.cr_warehouse_sk,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        COUNT(*) AS cnt_catalog_return
    FROM catalog_returns cr
    GROUP BY cr.cr_reason_sk, cr.cr_warehouse_sk
)
SELECT
    c_store.c_customer_id,
    c_store.c_first_name,
    c_store.c_last_name,
    cp.cp_department,
    cp.cp_type,
    r_store.r_reason_desc               AS store_return_reason,
    r_cat.r_reason_desc                 AS catalog_return_reason,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(sr.sr_return_amt)               AS total_store_return_amt,
    crs.total_catalog_return,
    CASE
        WHEN SUM(sr.sr_return_amt) > 1500 THEN 'High Store Return'
        ELSE 'Low Store Return'
    END                                 AS store_return_level,
    CASE
        WHEN crs.total_catalog_return > 1500 THEN 'High Catalog Return'
        ELSE 'Low Catalog Return'
    END                                 AS catalog_return_level,
    (
        SELECT MAX(w2.w_warehouse_sq_ft)
        FROM warehouse w2
        WHERE w2.w_state = w.w_state
    )                                   AS max_warehouse_sq_ft_in_state
FROM store_returns sr
JOIN customer c_store
    ON sr.sr_customer_sk = c_store.c_customer_sk
JOIN customer_demographics cd_store
    ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_returning_customer_sk = c_store.c_customer_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r_cat
    ON cr.cr_reason_sk = r_cat.r_reason_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c_store.c_customer_sk
JOIN catalog_return_agg crs
    ON crs.cr_reason_sk = cr.cr_reason_sk
   AND crs.cr_warehouse_sk = cr.cr_warehouse_sk
WHERE wp.wp_type = 'Home'
GROUP BY
    c_store.c_customer_id,
    c_store.c_first_name,
    c_store.c_last_name,
    cp.cp_department,
    cp.cp_type,
    r_store.r_reason_desc,
    r_cat.r_reason_desc,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    crs.total_catalog_return,
    w.w_state
ORDER BY total_store_return_amt DESC
LIMIT 100
