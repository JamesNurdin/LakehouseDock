WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT
    c.c_customer_id,
    cc.cc_name,
    p.p_promo_name,
    sm.sm_type,
    r.r_reason_desc,
    ws.ws_order_number,
    cr.cr_return_amount,
    sr.sr_return_amt,
    CASE
        WHEN cs.cs_net_profit > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_flag,
    SUM(cs.cs_net_paid) AS sum_net_paid,
    AVG(cs.cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.reason r
    ON (cr.cr_reason_sk = r.r_reason_sk OR sr.sr_reason_sk = r.r_reason_sk)
LEFT JOIN tpcds.web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN tpcds.web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    cd.cd_marital_status = 'M'
    AND ib.ib_upper_bound > 80000
    AND EXISTS (
        SELECT 1 FROM customer_sales cs2
        WHERE cs2.c_customer_sk = c.c_customer_sk
    )
GROUP BY
    c.c_customer_id,
    cc.cc_name,
    p.p_promo_name,
    sm.sm_type,
    r.r_reason_desc,
    ws.ws_order_number,
    cr.cr_return_amount,
    sr.sr_return_amt,
    CASE
        WHEN cs.cs_net_profit > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END
ORDER BY sum_net_paid DESC
LIMIT 100
