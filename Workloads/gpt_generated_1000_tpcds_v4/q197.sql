WITH sales_agg AS (
    SELECT
        d.d_year,
        cs.cs_item_sk,
        cc.cc_name,
        sm.sm_type,
        t.t_hour,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer cu ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_bill_customer_sk = cu.c_customer_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_refunded_customer_sk = cu.c_customer_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cu.c_birth_month IN (5, 6, 7)
      AND t.t_hour BETWEEN 8 AND 17
      AND i.inv_quantity_on_hand > 0
      AND s.s_state = 'CA'
      AND ws.ws_net_paid_inc_tax > 1000
      AND wr.wr_fee < 50
    GROUP BY d.d_year, cs.cs_item_sk, cc.cc_name, sm.sm_type, t.t_hour
)
SELECT
    d_year,
    cs_item_sk,
    cc_name,
    sm_type,
    t_hour,
    total_net_paid,
    total_discount,
    sales_cnt,
    CASE WHEN total_net_paid > 100000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
