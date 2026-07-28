WITH joined_all AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_class,
        cc.cc_rec_start_date,
        cs.cs_order_number,
        cs.cs_net_profit,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN customer cust
        ON cs.cs_bill_customer_sk = cust.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN store_returns sr
        ON sr.sr_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = cs.cs_bill_customer_sk
    WHERE cc.cc_class = 'Particular'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cc.cc_rec_start_date BETWEEN DATE '2001-01-01' AND DATE '2003-12-31'
      AND sm.sm_type = 'AIR'
),
agg_per_cc AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        SUM(cs_net_profit) AS total_profit,
        SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_loss,
        COUNT(DISTINCT cs_order_number) AS order_cnt
    FROM joined_all
    GROUP BY cc_call_center_sk, cc_name
)
SELECT
    cc_call_center_sk,
    cc_name,
    total_profit,
    total_loss,
    order_cnt,
    total_profit / NULLIF(order_cnt, 0) AS profit_per_order
FROM agg_per_cc
WHERE total_profit / NULLIF(order_cnt, 0) > 1000
ORDER BY profit_per_order DESC
