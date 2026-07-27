WITH aggregated AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit)                         AS store_sales_profit,
        SUM(cs.cs_net_profit)                         AS catalog_sales_profit,
        SUM(ws.ws_net_profit)                         AS web_sales_profit,
        -SUM(COALESCE(sr.sr_net_loss, 0))              AS store_returns_profit,
        -SUM(COALESCE(wr.wr_net_loss, 0))              AS web_returns_profit
    FROM store_sales ss
    JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p_ss
      ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r_sr
      ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN catalog_sales cs
      ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN promotion p_cs
      ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
      ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN promotion p_ws
      ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE ib.ib_upper_bound >= 70000
      AND c.c_preferred_cust_flag = 'Y'
      AND s.s_state = 'CA'
      AND p_ss.p_discount_active = 'Y'
      AND cc.cc_class = 'M'
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 1
      AND r_sr.r_reason_desc = 'Damaged'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state
)
SELECT
    a.s_store_name,
    a.s_state,
    a.store_sales_profit,
    a.catalog_sales_profit,
    a.web_sales_profit,
    (a.store_sales_profit + a.catalog_sales_profit + a.web_sales_profit) AS total_profit,
    RANK() OVER (ORDER BY (a.store_sales_profit + a.catalog_sales_profit + a.web_sales_profit) DESC) AS profit_rank,
    CASE
        WHEN (a.store_sales_profit + a.catalog_sales_profit + a.web_sales_profit) > 100000 THEN 'High'
        ELSE 'Medium'
    END AS profit_category,
    (SELECT AVG(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) FROM promotion p) AS avg_active_promo_ratio
FROM aggregated a
ORDER BY profit_rank
LIMIT 100
