WITH cs_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        SUM(cs.cs_net_paid) AS order_net_paid,
        SUM(cs.cs_quantity) AS total_quantity
    FROM tpcds.catalog_sales cs
    GROUP BY cs.cs_order_number, cs.cs_item_sk, cs.cs_call_center_sk, cs.cs_promo_sk
)
SELECT
    s.s_store_id,
    s.s_market_desc,
    r.r_reason_desc,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(cs_agg.order_net_paid) AS total_catalog_sales,
    SUM(ws.ws_net_paid) AS total_web_sales,
    (SUM(cs_agg.order_net_paid) + SUM(ws.ws_net_paid) - SUM(sr.sr_net_loss)) AS net_contribution,
    p_ws.p_promo_name AS web_promo_name,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(cs_agg.order_net_paid) DESC) AS state_sales_rank
FROM tpcds.store_returns sr
JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN tpcds.household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN cs_agg
    ON cs_agg.cs_order_number = cr.cr_order_number
   AND cs_agg.cs_item_sk = cr.cr_item_sk
JOIN tpcds.call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.promotion p_cs
    ON cs_agg.cs_promo_sk = p_cs.p_promo_sk
JOIN tpcds.web_sales ws
    ON ws.ws_promo_sk = p_cs.p_promo_sk
   AND ws.ws_bill_cdemo_sk = cd_sr.cd_demo_sk
   AND ws.ws_bill_hdemo_sk = hd_sr.hd_demo_sk
JOIN tpcds.promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
WHERE s.s_country = 'United States'
GROUP BY s.s_store_id, s.s_market_desc, r.r_reason_desc, s.s_state, p_ws.p_promo_name
HAVING SUM(sr.sr_net_loss) > 1000
ORDER BY net_contribution DESC
LIMIT 100
