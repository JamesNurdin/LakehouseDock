WITH unified AS (
    SELECT
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_net_paid AS amount,
        1 AS sign,
        cs.cs_bill_hdemo_sk AS demo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        cr.cr_warehouse_sk AS warehouse_sk,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_refunded_cash AS amount,
        -1 AS sign,
        cr.cr_refunded_hdemo_sk AS demo_sk
    FROM catalog_returns cr
),
 daily AS (
    SELECT
        u.warehouse_sk,
        u.date_sk,
        SUM(CASE WHEN u.sign = 1 THEN u.amount ELSE 0 END) AS daily_sales_amount,
        SUM(CASE WHEN u.sign = -1 THEN u.amount ELSE 0 END) AS daily_return_amount,
        SUM(u.sign * u.amount) AS daily_net_amount,
        u.demo_sk
    FROM unified u
    GROUP BY u.warehouse_sk, u.date_sk, u.demo_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    d.date_sk,
    d.daily_sales_amount,
    d.daily_return_amount,
    d.daily_net_amount,
    CASE WHEN d.daily_net_amount >= 0 THEN 'Profit' ELSE 'Loss' END AS day_status,
    SUM(d.daily_net_amount) OVER (PARTITION BY w.w_warehouse_sk ORDER BY d.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_amount,
    AVG(hd.hd_income_band_sk) OVER (PARTITION BY w.w_warehouse_sk, d.date_sk) AS avg_income_band
FROM daily d
JOIN warehouse w
    ON w.w_warehouse_sk = d.warehouse_sk
LEFT JOIN household_demographics hd
    ON hd.hd_demo_sk = d.demo_sk
ORDER BY w.w_warehouse_id, d.date_sk
