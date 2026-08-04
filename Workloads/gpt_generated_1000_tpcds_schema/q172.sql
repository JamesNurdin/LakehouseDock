WITH agg AS (
    SELECT
        cc.cc_name,
        w.w_warehouse_name,
        cd.cd_gender,
        td.t_hour,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_paid,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE cc.cc_state = 'CA'
      AND w.w_gmt_offset = -6.00
      AND td.t_hour >= 12
      AND cs.cs_net_paid_inc_ship_tax > 500
    GROUP BY CUBE (cc.cc_name, w.w_warehouse_name, cd.cd_gender, td.t_hour)
)
SELECT
    cc_name,
    w_warehouse_name,
    cd_gender,
    t_hour,
    total_paid,
    total_loss,
    order_cnt,
    RANK() OVER (PARTITION BY cc_name ORDER BY total_paid DESC) AS warehouse_rank
FROM agg
ORDER BY cc_name, warehouse_rank
LIMIT 100
