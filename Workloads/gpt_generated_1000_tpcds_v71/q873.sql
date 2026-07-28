WITH ss_agg AS (
    SELECT
        ss_promo_sk,
        ss_sold_time_sk,
        ss_sold_date_sk,
        ss_store_sk,
        SUM(ss_net_paid)        AS total_net_paid,
        SUM(ss_net_profit)      AS total_net_profit,
        COUNT(*)                AS sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY ss_promo_sk, ss_sold_time_sk, ss_sold_date_sk, ss_store_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    cp.cp_department,
    r.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    t.t_hour,
    ss_agg.total_net_paid,
    ss_agg.total_net_profit,
    SUM(cr.cr_return_amount)                AS total_return_amount,
    SUM(wr.wr_return_amt)                   AS total_web_return_amount,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ss_agg.total_net_paid DESC) AS promo_rank,
    CASE
        WHEN ib.ib_lower_bound >= 150000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 80000  THEN 'Mid Income'
        ELSE 'Low Income'
    END                                   AS income_category,
    (SELECT COUNT(DISTINCT cd_demo_sk) FROM customer_demographics) AS total_demo_cnt
FROM ss_agg
INNER JOIN promotion p
        ON ss_agg.ss_promo_sk = p.p_promo_sk
INNER JOIN time_dim t
        ON ss_agg.ss_sold_time_sk = t.t_time_sk
INNER JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
INNER JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
INNER JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
INNER JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
INNER JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
INNER JOIN reason r2
        ON wr.wr_reason_sk = r2.r_reason_sk
WHERE p.p_discount_active = 'Y'
  AND t.t_hour BETWEEN 9 AND 17
  AND ib.ib_upper_bound <= 200000
  AND EXISTS (
        SELECT 1
        FROM reason r_chk
        WHERE r_chk.r_reason_desc = r.r_reason_desc
          AND r_chk.r_reason_id = 'R001'
    )
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    cp.cp_department,
    r.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    t.t_hour,
    ss_agg.total_net_paid,
    ss_agg.total_net_profit,
    CASE
        WHEN ib.ib_lower_bound >= 150000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 80000  THEN 'Mid Income'
        ELSE 'Low Income'
    END
ORDER BY ss_agg.total_net_paid DESC
LIMIT 100
