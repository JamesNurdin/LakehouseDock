WITH sales_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        w.w_state AS state,
        d.d_quarter_name AS quarter,
        CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'Discount' ELSE 'No Discount' END AS discount_flag,
        SUM(cs.cs_net_paid) AS sum_net_paid,
        AVG(cs.cs_ext_wholesale_cost) AS avg_wholesale_cost,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_fy_quarter_seq IN (16, 10, 17)
        AND d.d_qoy = 3
        AND w.w_gmt_offset = -6.00
        AND w.w_county = 'Bronx County'
        AND cs.cs_ext_wholesale_cost > 2000.00
        AND cs.cs_sold_time_sk BETWEEN 30000 AND 60000
    GROUP BY
        w.w_warehouse_name,
        w.w_state,
        d.d_quarter_name,
        CASE WHEN cs.cs_ext_discount_amt > 0 THEN 'Discount' ELSE 'No Discount' END
)
SELECT
    warehouse_name,
    state,
    quarter,
    discount_flag,
    sum_net_paid,
    avg_wholesale_cost,
    order_cnt,
    RANK() OVER (PARTITION BY state ORDER BY sum_net_paid DESC) AS rank_within_state,
    SUM(sum_net_paid) OVER (PARTITION BY state ORDER BY sum_net_paid DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_state_sales
FROM sales_agg
WHERE sum_net_paid > 10000.00
ORDER BY sum_net_paid DESC
LIMIT 100
