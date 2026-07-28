WITH joined AS (
    SELECT
        cr.cr_return_amount,
        d.d_year,
        d.d_dom,
        t.t_minute,
        c.c_customer_id,
        c.c_birth_country,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        cp.cp_department,
        ws.web_name
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_dom = 15
      AND t.t_minute = 5
      AND ib.ib_upper_bound >= 150000
      AND c.c_birth_country = 'United States'
),
agg AS (
    SELECT
        d_year,
        c_customer_id,
        cp_department,
        web_name,
        ib_upper_bound,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM joined
    GROUP BY d_year, c_customer_id, cp_department, web_name, ib_upper_bound
)
SELECT
    d_year,
    c_customer_id,
    cp_department,
    web_name,
    total_return_amount,
    return_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS revenue_rank,
    CASE WHEN ib_upper_bound >= 150000 THEN 'HighIncome' ELSE 'LowIncome' END AS income_category
FROM agg
ORDER BY d_year, revenue_rank
LIMIT 100
