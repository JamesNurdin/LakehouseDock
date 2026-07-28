WITH joined_data AS (
    SELECT
        d.d_date,
        d.d_year,
        sm.sm_carrier,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_category,
        cr.cr_return_amount,
        ws.ws_net_paid,
        ws.ws_quantity,
        cd_ref.cd_marital_status,
        cd_bill.cd_education_status,
        t.t_minute
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'MSC'
      AND cd_ref.cd_marital_status = 'M'
      AND cd_bill.cd_education_status = '4 yr Degree'
      AND t.t_minute BETWEEN 0 AND 15
      AND cr.cr_return_amount > 50
      AND ws.ws_quantity >= 2
),
agg_data AS (
    SELECT
        d_date,
        d_year,
        sm_carrier,
        return_category,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid) AS total_net_paid
    FROM joined_data
    GROUP BY d_date, d_year, sm_carrier, return_category
)
SELECT
    d_date,
    d_year,
    sm_carrier,
    return_category,
    total_return_amount,
    total_net_paid,
    RANK() OVER (PARTITION BY sm_carrier ORDER BY total_return_amount DESC) AS return_amount_rank,
    SUM(total_net_paid) OVER (PARTITION BY sm_carrier ORDER BY d_date ROWS UNBOUNDED PRECEDING) AS cumulative_net_paid
FROM agg_data
ORDER BY total_return_amount DESC
LIMIT 100
