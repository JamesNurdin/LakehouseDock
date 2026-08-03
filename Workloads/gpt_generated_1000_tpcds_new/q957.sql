WITH promo_cte AS (
    SELECT
        p_promo_sk,
        p_promo_name,
        p_channel_catalog,
        p_start_date_sk
    FROM promotion
    WHERE p_response_target = 1
)
SELECT
    s.s_state,
    pc.p_promo_name,
    ib.ib_income_band_sk,
    SUM(ss.ss_net_paid)                     AS total_store_sales,
    SUM(cs.cs_net_paid)                     AS total_catalog_sales,
    SUM(ws.ws_net_paid)                     AS total_web_sales,
    COUNT(DISTINCT ss.ss_ticket_number)    AS distinct_store_tickets,
    AVG(ws.ws_net_paid_inc_tax)            AS avg_web_net_paid_inc_tax,
    (
        SELECT COUNT(*)
        FROM customer_demographics cd_sub
        WHERE cd_sub.cd_education_status = 'College'
    )                                        AS total_college_customers
FROM store_sales ss
RIGHT OUTER JOIN promo_cte pc
    ON ss.ss_promo_sk = pc.p_promo_sk
INNER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
INNER JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
INNER JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN catalog_sales cs
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE s.s_state = 'TX'
  AND s.s_rec_start_date > DATE '2000-01-01'
  AND pc.p_channel_catalog = 'N'
  AND pc.p_start_date_sk >= 2450347
  AND ib.ib_upper_bound >= 50000
  AND ws.ws_net_paid_inc_tax > 2000
GROUP BY s.s_state, pc.p_promo_name, ib.ib_income_band_sk
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY total_store_sales DESC
LIMIT 100
