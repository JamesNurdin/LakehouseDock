WITH sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        d.d_year,
        d.d_month_seq
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    w.w_warehouse_name,
    cc.cc_name,
    s.d_year,
    s.d_month_seq,
    sum(s.cs_net_paid) AS total_sales_net_paid,
    sum(s.cs_net_profit) AS total_sales_net_profit,
    coalesce(sum(r.cr_return_amount), 0) AS total_return_amount,
    sum(s.cs_net_profit) - coalesce(sum(r.cr_return_amount), 0) AS net_profit_after_returns,
    avg(s.cs_ext_discount_amt) AS avg_discount_amount,
    count(DISTINCT s.cs_order_number) AS distinct_order_count
FROM sales s
JOIN warehouse w
    ON s.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON s.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN returns r
    ON s.cs_order_number = r.cr_order_number
GROUP BY w.w_warehouse_name, cc.cc_name, s.d_year, s.d_month_seq
ORDER BY w.w_warehouse_name, cc.cc_name, s.d_year, s.d_month_seq
