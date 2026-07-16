SELECT
    cc.cc_manager AS call_center_manager,
    ws.web_manager AS web_manager,
    ib.ib_income_band_sk AS income_band_id,
    COUNT(*) AS num_sales,
    SUM(ss.ss_net_paid) AS total_net_paid,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
FROM
    store_sales ss
    JOIN income_band ib
        ON ss.ss_net_paid >= ib.ib_lower_bound
        AND ss.ss_net_paid < ib.ib_upper_bound
    JOIN call_center cc
        ON ss.ss_store_sk = cc.cc_call_center_sk
    JOIN web_site ws
        ON cc.cc_state = ws.web_state
        AND cc.cc_city = ws.web_city
WHERE
    cc.cc_state IN ('TN', 'GA')
    AND ws.web_country = 'United States'
    AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451215
GROUP BY
    cc.cc_manager,
    ws.web_manager,
    ib.ib_income_band_sk
HAVING
    SUM(ss.ss_net_profit) > 10000
ORDER BY
    total_net_profit DESC
LIMIT 100
