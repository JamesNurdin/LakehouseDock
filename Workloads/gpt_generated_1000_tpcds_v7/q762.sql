WITH joined AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        cs.cs_net_profit AS catalog_profit,
        ws.ws_net_profit AS web_profit,
        p.p_discount_active,
        cc.cc_name,
        cp.cp_department,
        sm.sm_type,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        ws.ws_net_paid_inc_ship_tax,
        cs.cs_quantity,
        d.d_year,
        we.web_street_number
    FROM date_dim d
    JOIN catalog_sales cs               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr            ON cr.cr_order_number = cs.cs_order_number
    JOIN inventory inv                 ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s                       ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws                  ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp                   ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we                   ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2000
      AND we.web_street_number = '805'
      AND ws.ws_net_paid_inc_ship_tax > 5000
      AND cs.cs_quantity >= 10
      AND hd.hd_vehicle_count > 1
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        w_warehouse_id,
        w_city,
        SUM(catalog_profit) AS total_catalog_profit,
        SUM(web_profit) AS total_web_profit,
        SUM(catalog_profit) + SUM(web_profit) AS total_profit
    FROM joined
    GROUP BY w_warehouse_id, w_city
)
SELECT
    w_warehouse_id,
    w_city,
    total_catalog_profit,
    total_web_profit,
    total_profit,
    DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    CASE
        WHEN total_profit >= 100000 THEN 'Platinum'
        WHEN total_profit >= 50000 THEN 'Gold'
        WHEN total_profit >= 20000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier
FROM agg
ORDER BY profit_rank, w_warehouse_id
