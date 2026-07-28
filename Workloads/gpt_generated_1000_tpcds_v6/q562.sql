WITH max_income AS (
    SELECT max(ib_upper_bound) AS max_ub
    FROM income_band
)
SELECT
    s.s_store_id,
    s.s_state,
    cc.cc_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_transactions,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    CASE
        WHEN SUM(ss.ss_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_flag,
    (SELECT max_ub FROM max_income) AS max_income_upper_bound
FROM store s
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer c_sales
    ON ss.ss_customer_sk = c_sales.c_customer_sk
JOIN customer_demographics cd_sales
    ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
JOIN household_demographics hd_sales
    ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN customer_address ca_sales
    ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_store_ret
    ON sr.sr_reason_sk = r_store_ret.r_reason_sk
JOIN customer c_ret
    ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN customer_demographics cd_ret
    ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret
    ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c_sales.c_customer_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r_cat_ret
    ON cr.cr_reason_sk = r_cat_ret.r_reason_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c_sales.c_customer_sk
JOIN reason r_web_ret
    ON wr.wr_reason_sk = r_web_ret.r_reason_sk
JOIN household_demographics hd_income
    ON hd_sales.hd_income_band_sk = hd_income.hd_income_band_sk
JOIN income_band ib
    ON hd_income.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY
    s.s_store_id,
    s.s_state,
    cc.cc_name
ORDER BY total_net_profit DESC
LIMIT 100
