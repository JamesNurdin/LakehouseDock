WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_amt,
        wr.wr_net_loss,
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        cc.cc_call_center_sk,
        cc.cc_state,
        w.w_warehouse_sk,
        w.w_state,
        c.c_customer_sk,
        c.c_birth_country,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        td_cs.t_hour
    FROM catalog_sales cs
    JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_wr_refund ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
    JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
    JOIN household_demographics hd_wr_refund ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
    JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_brand = 'Brand#12'
      AND c.c_birth_country = 'SEYCHELLES'
      AND cc.cc_state = 'CA'
      AND hd.hd_income_band_sk IN (11, 14)
      AND i.i_current_price > 100
),
intersect_items AS (
    SELECT i_item_sk FROM joined_data WHERE cs_net_paid > 1000
    INTERSECT
    SELECT i_item_sk FROM joined_data WHERE cr_return_amount > 100
)
SELECT
    t.i_category,
    t.i_brand,
    t.total_sales,
    t.order_cnt,
    t.avg_return_amount,
    t.min_store_return,
    t.max_web_return,
    t.inv_quantity_on_hand,
    t.promo_cnt
FROM (
    SELECT
        jd.i_category,
        jd.i_brand,
        SUM(jd.cs_net_paid) AS total_sales,
        COUNT(DISTINCT jd.cs_order_number) AS order_cnt,
        AVG(jd.cr_return_amount) AS avg_return_amount,
        MIN(jd.sr_return_amt) AS min_store_return,
        MAX(jd.wr_return_amt) AS max_web_return,
        inv.inv_quantity_on_hand,
        l.promo_cnt,
        ROW_NUMBER() OVER (PARTITION BY jd.i_category ORDER BY SUM(jd.cs_net_paid) DESC) AS rnk
    FROM joined_data jd
    JOIN intersect_items ii ON jd.i_item_sk = ii.i_item_sk
    JOIN inventory inv ON inv.inv_item_sk = jd.i_item_sk AND inv.inv_warehouse_sk = jd.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS promo_cnt
        FROM promotion p3
        WHERE p3.p_item_sk = jd.i_item_sk
    ) l
    GROUP BY jd.i_category, jd.i_brand, inv.inv_quantity_on_hand, l.promo_cnt, jd.i_item_sk, jd.w_warehouse_sk
) t
WHERE t.rnk <= 5
ORDER BY t.total_sales DESC
LIMIT 100
