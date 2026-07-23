WITH sales_returns_agg AS (
    SELECT
        cc.cc_call_center_id AS cc_call_center_id,
        w.w_warehouse_id AS w_warehouse_id,
        cd.cd_gender AS cd_gender,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS return_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 500.00
        AND cs.cs_ext_discount_amt < 200.00
        AND cd.cd_purchase_estimate >= 2500
        AND w.w_warehouse_sq_ft > 500000
        AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
        AND cc.cc_state = 'CA'
    GROUP BY cc.cc_call_center_id, w.w_warehouse_id, cd.cd_gender
)
SELECT
    cc_call_center_id,
    w_warehouse_id,
    cd_gender,
    total_net_paid,
    total_discount,
    total_return_loss,
    order_cnt,
    return_cnt,
    total_net_paid / order_cnt AS avg_net_paid_per_order,
    total_net_paid - total_return_loss AS net_after_returns
FROM sales_returns_agg
WHERE total_net_paid > 2000
ORDER BY avg_net_paid_per_order DESC
LIMIT 100
