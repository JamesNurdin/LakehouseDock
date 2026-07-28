-- goal: Analyze return and web sales performance by customer gender, education, household vehicle count, and return reason, applying several filters, aggregations, a CASE flag, a scalar subquery, and a window rank.
WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_reason_sk,
        r.r_reason_desc,
        sr.sr_cdemo_sk,
        cd.cd_gender,
        cd.cd_education_status,
        sr.sr_hdemo_sk,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        sr.sr_return_ship_cost,
        sr.sr_reversed_charge
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
),
agg AS (
    SELECT
        b.cd_gender,
        b.cd_education_status,
        b.hd_vehicle_count,
        b.r_reason_desc,
        SUM(b.sr_return_amt)                         AS total_return_amount,
        AVG(ws.ws_ext_sales_price)                   AS avg_sales_price,
        COUNT(*)                                      AS txn_count,
        MAX(ws.ws_net_profit)                        AS max_net_profit,
        MIN(ws.ws_ext_ship_cost)                     AS min_ship_cost,
        SUM(b.sr_net_loss)                           AS total_net_loss
    FROM base b
    JOIN web_sales ws
        ON b.sr_cdemo_sk = ws.ws_bill_cdemo_sk
       AND b.sr_hdemo_sk = ws.ws_bill_hdemo_sk
    WHERE
        b.cd_gender = 'M'
        AND b.cd_education_status = 'College'
        AND b.hd_vehicle_count >= 2
        AND b.hd_income_band_sk IN (3, 5, 7)
        AND b.r_reason_desc LIKE '%Defect%'
        AND b.sr_return_amt > 1000
        AND ws.ws_ext_list_price BETWEEN 5000 AND 20000
        AND ws.ws_warehouse_sk = 2
        AND ws.ws_ext_ship_cost < 500
    GROUP BY
        b.cd_gender,
        b.cd_education_status,
        b.hd_vehicle_count,
        b.r_reason_desc
)
SELECT
    a.cd_gender,
    a.cd_education_status,
    a.hd_vehicle_count,
    a.r_reason_desc,
    a.total_return_amount,
    a.avg_sales_price,
    a.txn_count,
    a.max_net_profit,
    a.min_ship_cost,
    CASE WHEN a.total_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT AVG(sr_return_amt) FROM store_returns)               AS overall_avg_return_amt,
    ROW_NUMBER() OVER (PARTITION BY a.cd_gender ORDER BY a.total_return_amount DESC) AS gender_rank
FROM agg a
ORDER BY
    a.total_return_amount DESC,
    a.avg_sales_price DESC
LIMIT 100
