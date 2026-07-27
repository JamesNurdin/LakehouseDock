WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_time_sk AS time_sk,
        t.t_hour,
        t.t_sub_shift,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        sm.sm_type,
        w.w_state,
        p.p_discount_active,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
                               AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk = 5
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
),
ss AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_sold_time_sk AS time_sk,
        t.t_hour,
        t.t_sub_shift,
        c.c_customer_id,
        cd.cd_education_status,
        hd.hd_buy_potential,
        s.s_store_name,
        s.s_state,
        s.s_city
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE t.t_sub_shift = 'morning'
      AND s.s_state = 'TX'
      AND cd.cd_education_status LIKE '%Degree%'
      AND hd.hd_buy_potential = '500-1000'
      AND ss.ss_quantity > 5
      AND ss.ss_net_paid > 100
),
wr AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_returned_time_sk AS time_sk,
        t.t_hour,
        t.t_sub_shift,
        c.c_customer_id,
        cd.cd_marital_status,
        hd.hd_vehicle_count,
        wp.wp_type,
        r.r_reason_desc
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wp.wp_type = 'product'
      AND t.t_hour >= 12
      AND cd.cd_marital_status = 'M'
      AND hd.hd_vehicle_count >= 2
      AND wr.wr_return_amt > 0
      AND wr.wr_return_quantity >= 1
)
SELECT
    cs.t_hour,
    cs.t_sub_shift,
    cs.c_customer_id,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    COUNT(DISTINCT ss.ss_sold_date_sk) AS store_sales_days,
    SUM(ss.ss_net_paid) AS store_net_paid,
    SUM(ss.ss_net_profit) AS store_net_profit,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_return_amt) AS web_return_amount,
    AVG(wr.wr_return_quantity) AS avg_web_return_qty
FROM cs
JOIN ss ON cs.time_sk = ss.time_sk
JOIN wr ON cs.time_sk = wr.time_sk
WHERE cs.c_customer_id IN (
    SELECT c2.c_customer_id
    FROM customer c2
    WHERE c2.c_preferred_cust_flag = 'Y'
)
GROUP BY cs.t_hour, cs.t_sub_shift, cs.c_customer_id
ORDER BY catalog_net_paid DESC
LIMIT 100
