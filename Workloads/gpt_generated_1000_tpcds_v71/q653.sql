WITH joined AS (
    SELECT
        cc.cc_name,
        cc.cc_manager,
        cc.cc_sq_ft,
        p.p_promo_name,
        p.p_promo_sk,
        sm.sm_type,
        w.w_warehouse_name,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_coupon_amt,
        cr.cr_return_amount,
        cr.cr_fee,
        r.r_reason_desc,
        wr.wr_return_amt,
        td.t_hour
    FROM store_sales ss
    JOIN time_dim td                     ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca_ss          ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN promotion p                     ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs                ON cs.cs_promo_sk = p.p_promo_sk
                                        AND cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc                  ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                     ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr              ON cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r                        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr                 ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim td_wr                  ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    WHERE
        cc.cc_manager = 'Ryan Burchett'
        AND cc.cc_sq_ft > 900000000
        AND p.p_promo_sk IN (1026, 1057)
        AND cs.cs_coupon_amt > 100
        AND cr.cr_fee BETWEEN 20 AND 40
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
              AND wp.wp_type = 'product'
        )
)
SELECT
    cc_name,
    cc_manager,
    p_promo_name,
    sm_type,
    w_warehouse_name,
    r_reason_desc,
    SUM(cs_net_paid)               AS total_net_paid,
    SUM(cr_return_amount)          AS total_return_amount,
    SUM(wr_return_amt)             AS total_web_return,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY SUM(cs_net_paid) DESC) AS rank_by_center
FROM joined
GROUP BY
    cc_name,
    cc_manager,
    p_promo_name,
    sm_type,
    w_warehouse_name,
    r_reason_desc
HAVING SUM(cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
