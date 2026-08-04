WITH cust_demo_full AS (
    -- Full outer join between Customer and Customer Demographics on the current demo key
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_employed_count
    FROM tpcds.customer c
    FULL OUTER JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
wr_enriched AS (
    -- Join Web Returns with Date, Time, the full‑outer‑joined Customer/Demo view, and the Demo table for the refunded customer
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_net_loss,
        d.d_date,
        d.d_year,
        d.d_quarter_name,
        t.t_time,
        t.t_am_pm,
        cd.cd_gender,
        cd.cd_dep_employed_count,
        c.c_first_name,
        c.c_last_name
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN cust_demo_full c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_quarter_name = '1900Q2'                                     -- filter 1
      AND t.t_am_pm = 'PM'                                                -- filter 2
      AND cd.cd_dep_employed_count >= 3                                   -- filter 3
      AND EXISTS (
            SELECT 1
            FROM tpcds.web_returns wr3
            WHERE wr3.wr_refunded_customer_sk = wr.wr_refunded_customer_sk
              AND wr3.wr_return_amt > 100.00
        )
),
with_lateral AS (
    -- Lateral subquery that returns the total refunded amount for the same returned date
    SELECT
        we.*,
        ld.daily_total
    FROM wr_enriched we
    LEFT JOIN LATERAL (
        SELECT SUM(wr2.wr_return_amt) AS daily_total
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_returned_date_sk = we.wr_returned_date_sk
    ) ld ON TRUE
),
agg AS (
    SELECT
        cd_gender,
        d_year,
        t_am_pm,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_tax) AS avg_return_tax,
        COUNT(*) AS return_cnt,
        MAX(wr_return_amt) AS max_return_amt,
        MIN(wr_return_amt) AS min_return_amt,
        SUM(CASE WHEN cd_gender = 'M' THEN wr_return_amt ELSE 0 END) AS male_return_sum,
        MAX(daily_total) AS daily_total
    FROM with_lateral
    GROUP BY cd_gender, d_year, t_am_pm, daily_total
)
SELECT
    cd_gender,
    d_year,
    t_am_pm,
    total_return_amt,
    avg_return_tax,
    return_cnt,
    max_return_amt,
    min_return_amt,
    male_return_sum,
    daily_total,
    LAG(total_return_amt) OVER (PARTITION BY cd_gender ORDER BY d_year, t_am_pm) AS lag_total_return
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
