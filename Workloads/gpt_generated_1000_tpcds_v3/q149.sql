SELECT
    cp.cp_department AS department,
    i.i_category AS category,
    td.t_hour AS hour_of_day,
    p.p_promo_name AS promo_name,
    hd.hd_buy_potential AS buy_potential,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(cs.cs_ext_sales_price) AS min_sales_price,
    MAX(cs.cs_ext_sales_price) AS max_sales_price,
    SUM(wr.wr_return_amt) AS total_return_amount
FROM catalog_sales cs
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_time_sk = td.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
   AND wp.wp_customer_sk = c.c_customer_sk
WHERE td.t_sub_shift = 'morning'
  AND p.p_channel_press = 'N'
  AND i.i_current_price > 100.00
GROUP BY
    cp.cp_department,
    i.i_category,
    td.t_hour,
    p.p_promo_name,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_net_paid DESC
LIMIT 100
