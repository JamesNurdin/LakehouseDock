WITH
store_agg AS (
    SELECT
        d_s.d_year AS year,
        i_s.i_category AS category,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(COALESCE(sr.sr_refunded_cash, 0)) AS store_refunds_cash,
        SUM(COALESCE(sr.sr_store_credit, 0)) AS store_refunds_credit
    FROM store_sales ss
    JOIN date_dim d_s ON ss.ss_sold_date_sk = d_s.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i_s ON ss.ss_item_sk = i_s.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    LEFT JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    GROUP BY d_s.d_year, i_s.i_category
),
catalog_agg AS (
    SELECT
        d_c.d_year AS year,
        i_c.i_category AS category,
        cc.cc_name AS call_center_name,
        SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(COALESCE(cr.cr_refunded_cash, 0)) AS catalog_refunds_cash
    FROM catalog_sales cs
    JOIN date_dim d_c ON cs.cs_sold_date_sk = d_c.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN item i_c ON cs.cs_item_sk = i_c.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    LEFT JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    LEFT JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    GROUP BY d_c.d_year, i_c.i_category, cc.cc_name
)
SELECT
    sa.year,
    sa.category,
    ca.call_center_name,
    sa.store_sales_net_paid,
    ca.catalog_sales_net_paid,
    (sa.store_profit + ca.catalog_profit) AS total_profit,
    (sa.store_refunds_cash + ca.catalog_refunds_cash) AS total_refunds
FROM store_agg sa
JOIN catalog_agg ca
  ON sa.year = ca.year
 AND sa.category = ca.category
ORDER BY sa.year DESC, total_profit DESC
LIMIT 100
