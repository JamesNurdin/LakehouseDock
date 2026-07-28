WITH ss_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, ss.ss_promo_sk, ss.ss_cdemo_sk, ss.ss_hdemo_sk
)
SELECT
    s.s_store_name,
    s.s_state,
    i.i_item_id,
    i.i_category,
    p.p_promo_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    cr.cr_return_quantity,
    sr.sr_return_quantity,
    ss_agg.total_sales,
    ss_agg.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY ss_agg.total_sales DESC) AS state_sales_rank,
    DENSE_RANK() OVER (ORDER BY ss_agg.total_sales DESC) AS global_sales_rank
FROM ss_agg
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN item i
    ON ss_agg.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON ss_agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs
    ON ss_agg.ss_item_sk = cs.cs_item_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
    AND cr.cr_item_sk = i.i_item_sk
LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN store_returns sr
    ON s.s_store_sk = sr.sr_store_sk
    AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
WHERE
    s.s_state = 'CA'
    AND i.i_category = 'Sports'
    AND sm.sm_type = 'AIR'
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
ORDER BY
    s.s_state,
    state_sales_rank
