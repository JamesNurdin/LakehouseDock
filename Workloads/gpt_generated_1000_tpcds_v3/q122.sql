WITH aggregated_sales AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        sm.sm_type,
        w.w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid) AS total_paid,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE
        cc.cc_state = 'CA'
        AND cc.cc_country = 'United States'
        AND cc.cc_gmt_offset BETWEEN -8 AND -5
        AND p.p_channel_demo = 'N'
        AND p.p_discount_active = 'N'
        AND sm.sm_type = 'AIR'
        AND w.w_state = 'CA'
        AND td.t_hour BETWEEN 9 AND 17
        AND cs.cs_quantity > 1
        AND cs.cs_ext_discount_amt > 0
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        sm.sm_type,
        w.w_warehouse_name
)
SELECT
    agg.cc_call_center_id,
    agg.cc_name,
    agg.sm_type,
    agg.w_warehouse_name,
    agg.total_profit,
    agg.total_paid,
    agg.sales_cnt,
    agg.avg_discount,
    agg.total_profit / overall.avg_profit AS profit_vs_avg
FROM aggregated_sales agg
CROSS JOIN (
    SELECT AVG(cs2.cs_net_profit) AS avg_profit
    FROM catalog_sales cs2
) overall
WHERE agg.total_profit > overall.avg_profit
ORDER BY agg.total_profit DESC
LIMIT 100
