WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_hdemo_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(*) AS num_returns
    FROM store_returns sr
    WHERE sr.sr_return_tax > 5.0
      AND sr.sr_return_quantity > 1
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk, sr.sr_hdemo_sk
),
ws_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(*) AS num_sales
    FROM web_sales ws
    WHERE ws.ws_quantity >= 1
      AND ws.ws_net_paid_inc_ship_tax > 0
    GROUP BY ws.ws_web_site_sk, ws.ws_ship_mode_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    wsite.web_name,
    r.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cc.cc_name,
    cp.cp_department,
    p1.p_promo_name AS catalog_promo_name,
    sm_cs.sm_type AS ship_mode_type,
    SUM(sragg.total_return_loss) AS total_return_loss,
    SUM(sragg.num_returns) AS total_return_cnt,
    SUM(wsagg.total_sales) AS total_web_sales,
    AVG(wsagg.avg_profit) AS avg_web_profit,
    CASE WHEN SUM(sragg.total_return_loss) > 0
         THEN ROUND(SUM(wsagg.total_sales) / SUM(sragg.total_return_loss), 2)
         ELSE NULL
    END AS sales_to_return_loss_ratio
FROM sr_agg sragg
JOIN store s ON sragg.sr_store_sk = s.s_store_sk
JOIN reason r ON sragg.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd ON sragg.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p1 ON cs.cs_promo_sk = p1.p_promo_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN household_demographics hd_wr_ref ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN household_demographics hd_wr_ret ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
JOIN ws_agg wsagg ON wsagg.ws_web_site_sk = ws.ws_web_site_sk
                     AND wsagg.ws_ship_mode_sk = ws.ws_ship_mode_sk
WHERE cc.cc_tax_percentage > 2.5
  AND s.s_state = 'CA'
  AND td_cs.t_hour BETWEEN 8 AND 18
  AND wsite.web_gmt_offset BETWEEN -5.0 AND 0.0
  AND cs.cs_ext_sales_price > (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = cs.cs_call_center_sk
    )
GROUP BY
    s.s_store_id,
    s.s_city,
    wsite.web_name,
    r.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cc.cc_name,
    cp.cp_department,
    p1.p_promo_name,
    sm_cs.sm_type
HAVING SUM(wsagg.total_sales) > 10000
ORDER BY sales_to_return_loss_ratio DESC
LIMIT 100
