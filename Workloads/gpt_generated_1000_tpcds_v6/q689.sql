SELECT
    w.w_warehouse_name,
    sm.sm_type,
    d_sold.d_year,
    SUM(cs.cs_net_profit) AS total_profit,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT p.p_promo_id) AS promo_cnt,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_sold.d_date_sk
GROUP BY w.w_warehouse_name, sm.sm_type, d_sold.d_year
HAVING SUM(cs.cs_net_profit) > 10000
   AND COUNT(DISTINCT p.p_promo_id) > 1
ORDER BY total_profit DESC
LIMIT 100
