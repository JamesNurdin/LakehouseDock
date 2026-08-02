WITH agg_base AS (
    SELECT
        cc.cc_name,
        i.i_brand,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(sr.sr_return_amt) AS total_store_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        CASE 
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
            WHEN SUM(cs.cs_net_profit) = 0 THEN 'BreakEven'
            ELSE 'Loss'
        END AS profit_flag
    FROM (
        SELECT * FROM item TABLESAMPLE BERNOULLI (20)
    ) AS i
    INNER JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
    INNER JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
    INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
    INNER JOIN customer_demographics cd_cr_refund ON cr.cr_refunded_cdemo_sk = cd_cr_refund.cd_demo_sk
    INNER JOIN customer_demographics cd_cr_return ON cr.cr_returning_cdemo_sk = cd_cr_return.cd_demo_sk
    INNER JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    INNER JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    INNER JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    INNER JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    INNER JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    INNER JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    INNER JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    INNER JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
    INNER JOIN customer_demographics cd_wr_return ON wr.wr_returning_cdemo_sk = cd_wr_return.cd_demo_sk
    INNER JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    INNER JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    INNER JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_category = 'Electronics'
      AND cd_cs.cd_purchase_estimate > 2000
      AND td_cs.t_am_pm = 'PM'
    GROUP BY GROUPING SETS (
        (cc.cc_name, i.i_brand),
        (cc.cc_name),
        (i.i_brand),
        ()
    )
)
SELECT
    cc_name,
    i_brand,
    total_net_paid,
    total_net_profit,
    profit_flag,
    order_cnt,
    total_return_amount,
    total_store_return_amount,
    total_web_return_amount,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS sales_rank,
    CASE 
        WHEN cc_name IS NOT NULL THEN (
            SELECT SUM(cs2.cs_net_paid)
            FROM catalog_sales cs2
            JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
            WHERE cc2.cc_name = agg_base.cc_name
        )
        ELSE NULL
    END AS cc_total_net_paid
FROM agg_base
WHERE total_net_paid > (
    SELECT AVG(cs3.cs_net_paid) FROM catalog_sales cs3
)
ORDER BY total_net_paid DESC
LIMIT 100
