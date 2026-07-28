WITH store_ret_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_reason_sk,
        sr.sr_cdemo_sk,
        SUM(sr.sr_return_amt)  AS total_return_amt,
        SUM(sr.sr_net_loss)   AS total_net_loss
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451910 AND 2452035  -- example surrogate key range for the year 2000
    GROUP BY sr.sr_item_sk, sr.sr_returned_date_sk, sr.sr_reason_sk, sr.sr_cdemo_sk
)
SELECT
    cc.cc_call_center_id,
    p.p_promo_name,
    r.r_reason_desc,
    d.d_year,
    SUM(cs.cs_net_paid)            AS total_sales,
    SUM(cs.cs_net_profit)          AS total_profit,
    SUM(sr_agg.total_return_amt)   AS total_returns,
    CASE
        WHEN SUM(cs.cs_net_profit) - SUM(sr_agg.total_return_amt) > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END                           AS overall_status
FROM store_ret_agg sr_agg
JOIN date_dim d
    ON sr_agg.sr_returned_date_sk = d.d_date_sk
JOIN item i
    ON sr_agg.sr_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN reason r
    ON sr_agg.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON sr_agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    d.d_year = 2000
    AND i.i_brand = 'Brand#23'
    AND cc.cc_state = 'CA'
    AND p.p_discount_active = 'Y'
GROUP BY
    cc.cc_call_center_id,
    p.p_promo_name,
    r.r_reason_desc,
    d.d_year
ORDER BY total_profit DESC
LIMIT 100
