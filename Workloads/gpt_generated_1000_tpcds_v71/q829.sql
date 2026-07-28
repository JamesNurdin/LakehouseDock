WITH sales AS (
    SELECT
        w.w_warehouse_name,
        p.p_promo_name,
        CAST(NULL AS varchar) AS r_reason_desc,
        td.t_hour,
        SUM(cs.cs_net_paid_inc_tax) AS sales_amount,
        SUM(cs.cs_quantity) AS units_sold,
        CAST(NULL AS decimal(7,2)) AS return_amount
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE p.p_channel_dmail = 'Y'
      AND td.t_hour BETWEEN 8 AND 20
    GROUP BY w.w_warehouse_name, p.p_promo_name, td.t_hour
),
returns AS (
    SELECT
        CAST(NULL AS varchar) AS w_warehouse_name,
        CAST(NULL AS varchar) AS p_promo_name,
        r.r_reason_desc,
        td.t_hour,
        CAST(NULL AS decimal(7,2)) AS sales_amount,
        CAST(NULL AS bigint) AS units_sold,
        SUM(wr.wr_return_amt) AS return_amount
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN household_demographics hd_refund ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY r.r_reason_desc, td.t_hour
)
SELECT
    dim.w_warehouse_name,
    dim.p_promo_name,
    dim.r_reason_desc,
    dim.t_hour AS hour,
    SUM(dim.sales_amount) AS total_sales,
    SUM(dim.return_amount) AS total_returns,
    SUM(dim.sales_amount) - SUM(dim.return_amount) AS net_amount,
    RANK() OVER (ORDER BY SUM(dim.sales_amount) - SUM(dim.return_amount) DESC) AS sales_rank,
    SUM(SUM(dim.sales_amount) - SUM(dim.return_amount)) OVER (
        ORDER BY SUM(dim.sales_amount) - SUM(dim.return_amount) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_amount
FROM (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM returns
) dim
GROUP BY dim.w_warehouse_name, dim.p_promo_name, dim.r_reason_desc, dim.t_hour
ORDER BY net_amount DESC
LIMIT 100
