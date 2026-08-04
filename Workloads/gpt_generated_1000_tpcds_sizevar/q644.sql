WITH cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sub1 AS (
        SELECT cs_order_number
        FROM cs_sample
    ),
    sub2 AS (
        SELECT ws_order_number AS cs_order_number
        FROM web_sales
    ),
    common_orders AS (
        SELECT cs_order_number
        FROM sub1
        INTERSECT
        SELECT cs_order_number
        FROM sub2
    ),
    joined_data AS (
        SELECT
            cs.cs_order_number,
            cs.cs_net_paid,
            cr.cr_net_loss,
            ws.ws_net_paid,
            wr.wr_net_loss,
            cc.cc_state,
            sm.sm_carrier,
            ib.ib_upper_bound,
            CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Profit' END AS return_status,
            td.t_hour
        FROM cs_sample cs
        JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
        JOIN time_dim td
            ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN inventory i
            ON w.w_warehouse_sk = i.inv_warehouse_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN web_sales ws
            ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
        WHERE cs.cs_order_number IN (SELECT cs_order_number FROM common_orders)
          AND cc.cc_state = 'CA'
          AND sm.sm_carrier = 'UPS'
          AND ib.ib_upper_bound > 50000
          AND td.t_hour BETWEEN 8 AND 17
    )
SELECT
    jd.cs_order_number,
    jd.cc_state,
    jd.sm_carrier,
    jd.ib_upper_bound,
    jd.return_status,
    jd.cs_net_paid,
    jd.cr_net_loss,
    jd.ws_net_paid,
    jd.wr_net_loss,
    (jd.cs_net_paid - COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.ws_net_paid, 0) - COALESCE(jd.wr_net_loss, 0)) AS total_net,
    ROW_NUMBER() OVER (
        PARTITION BY jd.cc_state
        ORDER BY (jd.cs_net_paid - COALESCE(jd.cr_net_loss, 0) + COALESCE(jd.ws_net_paid, 0) - COALESCE(jd.wr_net_loss, 0)) DESC
    ) AS state_rank
FROM joined_data jd
ORDER BY total_net DESC
LIMIT 100
