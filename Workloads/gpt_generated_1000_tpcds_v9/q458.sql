WITH base_data AS (
    SELECT
        cp.cp_catalog_page_id AS cp_catalog_page_id,
        cp.cp_department AS cp_department,
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS ship_type,
        hd.hd_buy_potential AS buy_potential,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_profit) AS total_cs_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_cr_loss,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_ws_profit,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_sr_loss,
        MIN(td_sh.t_hour) AS first_sale_hour,
        MAX(td_sh.t_hour) AS last_sale_hour
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td_sh ON cs.cs_sold_time_sk = td_sh.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                                AND sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    WHERE
        cp.cp_department IN ('Electronics', 'Clothing')
        AND hd.hd_buy_potential IN ('1001-5000', '>10000')
        AND sm.sm_type <> 'AIR'
        AND w.w_city = 'Seattle'
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450300
        AND r_cr.r_reason_desc LIKE '%damaged%'
        AND td_sh.t_hour BETWEEN 9 AND 18
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_department,
        w.w_warehouse_name,
        sm.sm_type,
        hd.hd_buy_potential
)
SELECT
    cp_catalog_page_id,
    cp_department,
    warehouse_name,
    ship_type,
    buy_potential,
    total_cs_profit,
    total_cr_loss,
    total_ws_profit,
    total_sr_loss,
    (total_cs_profit - total_cr_loss + total_ws_profit - total_sr_loss) AS adjusted_profit,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY (total_cs_profit - total_cr_loss + total_ws_profit - total_sr_loss) DESC) AS profit_rank
FROM base_data
WHERE (total_cs_profit - total_cr_loss + total_ws_profit - total_sr_loss) > 0
UNION
SELECT
    cp_catalog_page_id,
    cp_department,
    warehouse_name,
    ship_type,
    buy_potential,
    total_cs_profit,
    total_cr_loss,
    total_ws_profit,
    total_sr_loss,
    (total_cs_profit - total_cr_loss + total_ws_profit - total_sr_loss) AS adjusted_profit,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY (total_cs_profit - total_cr_loss + total_ws_profit - total_sr_loss) ASC) AS profit_rank
FROM base_data
WHERE (total_cs_profit - total_cr_loss + total_ws_profit - total_sr_loss) <= 0
ORDER BY cp_department, adjusted_profit DESC, profit_rank
