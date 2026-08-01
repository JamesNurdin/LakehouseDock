WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        w.w_state,
        t.t_hour,
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_location_type,
        cd.cd_credit_rating,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        cd.cd_credit_rating = 'Good'
        AND cd.cd_education_status = 'Advanced Degree'
        AND ca.ca_state = 'PA'
        AND ca.ca_location_type = 'single family'
        AND w.w_state = 'CA'
        AND t.t_hour BETWEEN 8 AND 12
        AND cd.cd_purchase_estimate >= 2000
        AND hd.hd_vehicle_count > 0
)
SELECT
    s.w_warehouse_name AS warehouse_name,
    s.ca_state AS customer_state,
    s.t_hour AS sold_hour,
    COUNT(DISTINCT s.cs_order_number) AS num_orders,
    SUM(s.cs_net_paid) AS total_sales,
    AVG(s.cs_net_profit) AS avg_profit,
    MIN(s.cs_quantity) AS min_quantity,
    MAX(s.cs_quantity) AS max_quantity,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    (
        SELECT SUM(cr2.cr_net_loss)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = s.w_warehouse_sk
    ) AS total_warehouse_net_loss
FROM sales_agg s
JOIN catalog_returns cr
    ON cr.cr_order_number = s.cs_order_number
    AND cr.cr_item_sk = s.cs_item_sk
    AND cr.cr_warehouse_sk = s.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_refunded_addr_sk = s.ca_address_sk
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
    AND wr.wr_returned_time_sk = t_ret.t_time_sk
JOIN customer_demographics cd_ret
    ON cr.cr_refunded_cdemo_sk = cd_ret.cd_demo_sk
    AND wr.wr_refunded_cdemo_sk = cd_ret.cd_demo_sk
JOIN household_demographics hd_ret
    ON cr.cr_refunded_hdemo_sk = hd_ret.hd_demo_sk
    AND wr.wr_refunded_hdemo_sk = hd_ret.hd_demo_sk
JOIN customer_address ca_ret
    ON cr.cr_refunded_addr_sk = ca_ret.ca_address_sk
    AND wr.wr_refunded_addr_sk = ca_ret.ca_address_sk
WHERE
    cr.cr_return_amount > 0
    AND wr.wr_return_amt > 0
GROUP BY
    s.w_warehouse_name,
    s.ca_state,
    s.t_hour,
    s.w_warehouse_sk
ORDER BY
    total_sales DESC,
    warehouse_name
LIMIT 100
