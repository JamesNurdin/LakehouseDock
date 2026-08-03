WITH base_data AS (
    SELECT
        cp.cp_department,
        cp.cp_description,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        cs.cs_net_paid,
        i.i_item_id,
        i.i_brand_id,
        i.i_current_price,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_id,
        w.w_state,
        r.r_reason_desc,
        sm.sm_type,
        wp.wp_type,
        sr.sr_net_loss
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cp.cp_description LIKE '%economic%'
      AND i.i_brand_id = 23
      AND hd.hd_income_band_sk IN (2, 17)
      AND w.w_state = 'CA'
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND wp.wp_type = 'cart'
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_return_amount > 0
      )
)
SELECT DISTINCT
    bd.cp_department,
    bd.c_customer_id,
    bd.cs_order_number,
    bd.cs_sold_date_sk,
    bd.cs_net_profit,
    bd.cs_net_paid,
    bd.i_item_id,
    bd.r_reason_desc,
    bd.sm_type,
    bd.wp_type,
    bd.sr_net_loss,
    RANK() OVER (PARTITION BY bd.cp_department ORDER BY bd.cs_net_profit DESC) AS profit_rank,
    AVG(bd.sr_net_loss) OVER (
        PARTITION BY bd.cp_department
        ORDER BY bd.cs_sold_date_sk
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ) AS loss_moving_avg_5
FROM base_data bd
ORDER BY bd.cp_department, profit_rank
LIMIT 100
