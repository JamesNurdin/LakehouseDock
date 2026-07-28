WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    WHERE
        t_ss.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND EXISTS (
            SELECT 1
            FROM catalog_returns cr
            JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
            JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
            JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
            WHERE cr.cr_item_sk = ss.ss_item_sk
              AND cr.cr_returned_time_sk = t_ss.t_time_sk
              AND cr.cr_reason_sk = r_sr.r_reason_sk
              AND sm.sm_carrier = 'UPS'
              AND cc.cc_company_name = 'Company A'
              AND cr.cr_return_amount > 100
        )
    GROUP BY s.s_store_id, s.s_store_name
)
SELECT
    s_store_id,
    s_store_name,
    total_profit,
    profit_category,
    distinct_tickets,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY profit_rank
LIMIT 100
