WITH
wr_agg AS (
    SELECT
        wr.wr_reason_sk,
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        MIN(wr.wr_refunded_customer_sk) AS refunded_customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    GROUP BY wr.wr_reason_sk, wr.wr_returned_date_sk, wr.wr_returned_time_sk
),
sales_pre AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 1000
      AND cs.cs_net_paid > 0
),
sales_joined AS (
    SELECT
        d.d_date AS event_date,
        'sale' AS event_type,
        s.cs_net_paid AS amount,
        CASE WHEN s.cs_net_paid > 0 THEN 'Positive' ELSE 'Negative' END AS amount_sign,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        cc.cc_name AS call_center_name,
        w.w_warehouse_name AS warehouse_name,
        NULL AS reason_desc,
        RANK() OVER (PARTITION BY d.d_year ORDER BY s.cs_net_paid DESC) AS rank_in_year
    FROM sales_pre s
    JOIN date_dim d ON s.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON s.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count >= 2
      AND d.d_fy_year = 1917
),
returns_joined AS (
    SELECT
        d.d_date AS event_date,
        'return' AS event_type,
        -a.total_return_amt AS amount,
        CASE WHEN a.total_return_amt > 0 THEN 'Negative' ELSE 'Positive' END AS amount_sign,
        cu.c_first_name || ' ' || cu.c_last_name AS customer_name,
        NULL AS call_center_name,
        NULL AS warehouse_name,
        r.r_reason_desc AS reason_desc,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY a.total_return_amt DESC) AS rank_in_year
    FROM wr_agg a
    JOIN date_dim d ON a.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON a.wr_returned_time_sk = t.t_time_sk
    JOIN customer cu ON a.refunded_customer_sk = cu.c_customer_sk
    JOIN reason r ON a.wr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cu.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND hd.hd_buy_potential = '>10000'
      AND d.d_fy_year = 1917
)
SELECT
    event_date,
    event_type,
    amount,
    amount_sign,
    customer_name,
    call_center_name,
    warehouse_name,
    reason_desc,
    rank_in_year
FROM sales_joined
UNION ALL
SELECT
    event_date,
    event_type,
    amount,
    amount_sign,
    customer_name,
    call_center_name,
    warehouse_name,
    reason_desc,
    rank_in_year
FROM returns_joined
ORDER BY event_date DESC, amount DESC
LIMIT 100
