WITH sales_agg AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_store_sales_profit,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        SUM(cs.cs_net_profit) AS total_catalog_sales_profit,
        SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
        SUM(wr.wr_net_loss) AS total_web_returns_loss,
        SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS net_gain
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk AND cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_date >= DATE '2002-01-01'
      AND d.d_date < DATE '2003-01-01'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 80000
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
    GROUP BY d.d_year, s.s_store_id, s.s_store_name
)
SELECT
    sa.d_year,
    sa.s_store_id,
    sa.s_store_name,
    sa.total_store_sales_profit,
    sa.total_store_returns_loss,
    sa.total_catalog_sales_profit,
    sa.total_catalog_returns_loss,
    sa.total_web_returns_loss,
    sa.net_gain,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY sa.net_gain DESC) AS store_year_rank,
    (SELECT AVG(ib2.ib_lower_bound) FROM income_band ib2) AS avg_income_lower_bound,
    CASE WHEN EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_cost > 1000) THEN 'Expensive' ELSE 'Regular' END AS promo_category
FROM sales_agg sa
ORDER BY sa.d_year, store_year_rank
LIMIT 100
