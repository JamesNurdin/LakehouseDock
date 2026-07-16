WITH sales_agg AS (
    SELECT
        cd.cd_education_status AS education,
        hd.hd_vehicle_count AS vehicle_cnt,
        DATE_TRUNC('month', date_add('day', ss.ss_sold_date_sk, DATE '1970-01-01')) AS sale_month,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cd.cd_education_status, hd.hd_vehicle_count, DATE_TRUNC('month', date_add('day', ss.ss_sold_date_sk, DATE '1970-01-01'))
),
returns_agg AS (
    SELECT
        cd.cd_education_status AS education,
        hd.hd_vehicle_count AS vehicle_cnt,
        DATE_TRUNC('month', date_add('day', wr.wr_returned_date_sk, DATE '1970-01-01')) AS return_month,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cd.cd_education_status, hd.hd_vehicle_count, DATE_TRUNC('month', date_add('day', wr.wr_returned_date_sk, DATE '1970-01-01'))
)
SELECT
    s.education,
    s.vehicle_cnt,
    s.sale_month,
    s.total_profit,
    COALESCE(r.total_loss, 0) AS total_loss,
    s.total_profit - COALESCE(r.total_loss, 0) AS net_contribution,
    RANK() OVER (PARTITION BY s.sale_month ORDER BY (s.total_profit - COALESCE(r.total_loss, 0)) DESC) AS month_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.education = r.education
    AND s.vehicle_cnt = r.vehicle_cnt
    AND s.sale_month = r.return_month
WHERE s.total_profit > 0
ORDER BY s.sale_month, month_rank
LIMIT 100
