WITH sales_demo AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count_sold
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
returns_demo AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sr.sr_return_quantity) AS total_quantity_returned,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count_return
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    s.cd_gender,
    s.cd_marital_status,
    s.avg_purchase_estimate,
    s.total_quantity_sold,
    r.total_quantity_returned,
    CASE
        WHEN s.total_quantity_sold = 0 THEN 0
        ELSE r.total_quantity_returned * 1.0 / s.total_quantity_sold
    END AS return_rate,
    CASE
        WHEN s.total_quantity_sold = 0 THEN NULL
        ELSE ROUND((s.total_quantity_sold - r.total_quantity_returned) * 1.0 / s.total_quantity_sold, 2)
    END AS keep_rate,
    DENSE_RANK() OVER (ORDER BY CASE
                                    WHEN s.total_quantity_sold = 0 THEN 0
                                    ELSE r.total_quantity_returned * 1.0 / s.total_quantity_sold
                                 END DESC) AS return_rate_rank,
    (s.avg_vehicle_count_sold + COALESCE(r.avg_vehicle_count_return, 0)) / 2 AS avg_vehicle_count_overall
FROM sales_demo s
LEFT JOIN returns_demo r
    ON s.cd_gender = r.cd_gender
    AND s.cd_marital_status = r.cd_marital_status
ORDER BY return_rate_rank
LIMIT 50
