/* goal: Summarize web return amounts by store and year with multiple demographic and location filters, then aggregate to yearly totals and rank years */
WITH per_store AS (
    SELECT
        s.s_store_id,
        d_ret.d_year,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd_refunded
        ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_demographics cd_returning
        ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_refunded
        ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_ret.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2000
      AND d_ret.d_month_seq BETWEEN 1 AND 12
      AND cd_refunded.cd_gender = 'F'
      AND cd_returning.cd_education_status = 'College'
      AND hd_refunded.hd_vehicle_count >= 2
      AND w.w_city = 'Lakeside'
      AND s.s_state = 'CA'
      AND ws.web_mkt_class LIKE '%services%'
    GROUP BY s.s_store_id, d_ret.d_year
),
per_year AS (
    SELECT
        d_year,
        SUM(total_return_amount) AS year_total_return,
        AVG(total_return_amount) AS year_avg_return,
        COUNT(*) AS store_count
    FROM per_store
    GROUP BY d_year
)
SELECT
    d_year,
    year_total_return,
    year_avg_return,
    store_count,
    ROW_NUMBER() OVER (ORDER BY year_total_return DESC) AS rn_year
FROM per_year
WHERE year_total_return > 5000
ORDER BY year_total_return DESC
LIMIT 100
