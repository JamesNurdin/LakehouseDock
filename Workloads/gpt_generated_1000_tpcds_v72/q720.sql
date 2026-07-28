WITH web_returns_agg AS (
    SELECT 
        i.i_item_sk,
        p.p_promo_id,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, p.p_promo_id
)
SELECT 
    cp.cp_catalog_page_number,
    cp.cp_department,
    sm.sm_type,
    cd_refund.cd_marital_status,
    hd_refund.hd_buy_potential,
    ib.ib_lower_bound,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(*) AS catalog_return_cnt,
    COALESCE(wra.web_net_loss, 0) AS web_net_loss_total,
    COALESCE(wra.web_return_cnt, 0) AS web_return_cnt
FROM catalog_returns cr
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_demographics cd_return ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
JOIN income_band ib ON hd_refund.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_returns_agg wra ON i.i_item_sk = wra.i_item_sk
WHERE cp.cp_department = 'Electronics'
  AND td.t_hour BETWEEN 9 AND 17
GROUP BY 
    cp.cp_catalog_page_number,
    cp.cp_department,
    sm.sm_type,
    cd_refund.cd_marital_status,
    hd_refund.hd_buy_potential,
    ib.ib_lower_bound,
    wra.web_net_loss,
    wra.web_return_cnt
ORDER BY catalog_net_loss DESC
LIMIT 100
