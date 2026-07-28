WITH aggregated AS (
    SELECT
        wsite.web_site_id,
        t.t_hour,
        cd.cd_gender,
        ib.ib_upper_bound AS income_upper,
        p.p_promo_id,
        sm.sm_type AS ship_mode_type,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amt,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amt
    FROM time_dim t
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND ib.ib_upper_bound >= 50000
      AND p.p_discount_active = 'Y'
      AND wsite.web_country = 'United States'
      AND ws.ws_quantity > 1
    GROUP BY wsite.web_site_id, t.t_hour, cd.cd_gender, ib.ib_upper_bound, p.p_promo_id, sm.sm_type
    HAVING SUM(ws.ws_net_profit) > 10000
)
SELECT
    ag.web_site_id,
    ag.t_hour,
    ag.cd_gender,
    ag.income_upper,
    ag.p_promo_id,
    ag.ship_mode_type,
    ag.total_net_profit,
    ag.total_sales,
    ag.distinct_orders,
    ag.total_catalog_return_amount,
    ag.total_store_return_amt,
    ag.total_web_return_amt,
    RANK() OVER (ORDER BY ag.total_net_profit DESC) AS profit_rank
FROM aggregated ag
ORDER BY ag.total_net_profit DESC, ag.web_site_id
LIMIT 100
