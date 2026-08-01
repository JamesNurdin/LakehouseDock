WITH sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        cc.cc_name AS call_center_name,
        p.p_promo_name AS promo_name,
        w.w_warehouse_name AS warehouse_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
                         AND sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE
        cc.cc_gmt_offset BETWEEN -5.00 AND 5.00
        AND p.p_discount_active = 'Y'
        AND p.p_channel_email = 'Y'
        AND cs.cs_net_profit > 0
        AND cr.cr_net_loss < 0
        AND cc.cc_rec_start_date >= DATE '2000-01-01'
        AND EXISTS (
            SELECT 1 FROM store s
            WHERE s.s_store_sk = sr.sr_store_sk
              AND s.s_state = 'CA'
        )
    GROUP BY GROUPING SETS (
        (c.c_customer_id, cd.cd_gender, cd.cd_education_status, cc.cc_name, p.p_promo_name, w.w_warehouse_name),
        (c.c_customer_id, cd.cd_gender, cd.cd_education_status),
        (cd.cd_gender, cd.cd_education_status),
        ()
    )
)
SELECT
    customer_id,
    gender,
    education_status,
    call_center_name,
    promo_name,
    warehouse_name,
    total_net_profit,
    total_net_loss,
    orders_count,
    (total_net_profit - total_net_loss) AS net_balance,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
WHERE total_net_profit > 1000
ORDER BY net_balance DESC
LIMIT 100
