WITH joined_data AS (
    SELECT
        cc.cc_state,
        i.i_category,
        t_sold.t_hour,
        cd.cd_gender,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cs.cs_ext_sales_price,
        cs.cs_order_number,
        sr.sr_return_amt,
        wr.wr_refunded_cash
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_category = 'Electronics'
      AND cs.cs_ext_tax > 50
)
SELECT
    cc_state,
    i_category,
    t_hour,
    cd_gender,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_ext_tax) AS avg_ext_tax,
    COUNT(DISTINCT cs_order_number) AS order_count,
    MIN(cs_ext_sales_price) AS min_sales_price,
    MAX(cs_ext_sales_price) AS max_sales_price,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(wr_refunded_cash) AS total_refunded_cash,
    CASE WHEN SUM(cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status
FROM joined_data
GROUP BY cc_state, i_category, t_hour, cd_gender
ORDER BY total_net_paid DESC
LIMIT 100
