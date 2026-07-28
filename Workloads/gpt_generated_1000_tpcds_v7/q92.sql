WITH avg_ret AS (
    SELECT cr_item_sk, avg(cr_return_amount) AS avg_ret_amt
    FROM catalog_returns
    GROUP BY cr_item_sk
)
SELECT
    cc.cc_company,
    cc.cc_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    i.i_brand,
    p.p_promo_name,
    sm.sm_type,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
    MAX(cs.cs_sold_date_sk) AS max_sold_date_sk,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    ar.avg_ret_amt
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN avg_ret ar ON ar.cr_item_sk = cs.cs_item_sk
WHERE
    cc.cc_company IN (1, 2, 3)
    AND cc.cc_hours = '8AM-8AM'
    AND hd.hd_vehicle_count >= 1
    AND hd.hd_buy_potential = '5001-10000'
    AND cs.cs_ext_ship_cost > 500
    AND cs.cs_ext_tax BETWEEN 10 AND 50
    AND cs.cs_sold_date_sk BETWEEN 2451545 AND 2451910
    AND i.i_current_price < 100
    AND EXISTS (
        SELECT 1 FROM reason r2
        WHERE r2.r_reason_sk = cr.cr_reason_sk
          AND r2.r_reason_desc LIKE '%Damaged%'
    )
GROUP BY
    cc.cc_company,
    cc.cc_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    i.i_brand,
    p.p_promo_name,
    sm.sm_type,
    ar.avg_ret_amt
ORDER BY total_net_paid DESC
LIMIT 100
