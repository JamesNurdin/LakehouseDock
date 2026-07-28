WITH sales_no_return AS (
    SELECT ss.*
    FROM store_sales ss
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_item_sk = ss.ss_item_sk
    )
)
SELECT
    d.d_year,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT snt.ss_ticket_number) AS distinct_orders,
    SUM(snt.ss_ext_sales_price) AS total_sales,
    SUM(snt.ss_net_profit) AS total_profit,
    CASE
        WHEN SUM(snt.ss_net_profit) > 1000000 THEN 'HIGH'
        WHEN SUM(snt.ss_net_profit) > 500000  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (SELECT AVG(p2.p_cost) FROM promotion p2) AS avg_promo_cost,
    cp.cp_type
FROM sales_no_return snt
JOIN date_dim d
    ON snt.ss_sold_date_sk = d.d_date_sk               -- join rule 1
JOIN time_dim t
    ON snt.ss_sold_time_sk = t.t_time_sk               -- join rule 2
JOIN customer_demographics cd
    ON snt.ss_cdemo_sk = cd.cd_demo_sk                -- join rule 3
JOIN household_demographics hd
    ON snt.ss_hdemo_sk = hd.hd_demo_sk                -- join rule 4
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk    -- join rule 5
JOIN promotion p
    ON snt.ss_promo_sk = p.p_promo_sk                 -- join rule 6
LEFT JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk               -- left outer join (optional catalog page)
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk                     -- join rule 7
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = snt.ss_ticket_number
   AND sr.sr_item_sk = snt.ss_item_sk                  -- left join to capture possible return info
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk                 -- left join for return reason (may be null)
-- Web side of the model (reuse date_dim and time_dim via the same keys)
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk                 -- join rule 8 (web_sales to date_dim)
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk             -- join rule 9 (web_sales to time_dim)
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk           -- join rule 10
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk         -- join rule 11
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk                -- reuse promotion under a different alias
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk                  -- join rule 12
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk              -- join rule 13
WHERE d.d_year = 2001                                 -- restrict to a single year for illustration
GROUP BY
    d.d_year,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cp.cp_type
HAVING SUM(snt.ss_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
