WITH base_join AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        dd.d_year,
        cd.cd_gender,
        hd.hd_income_band_sk,
        cr.cr_return_amount,
        wr.wr_return_amt,
        ws.web_name,
        wr.wr_reversed_charge
    FROM catalog_returns cr
    JOIN date_dim dd
        ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = dd.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = dd.d_date_sk
),
filtered_1999 AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        d_year,
        cd_gender,
        hd_income_band_sk,
        SUM(cr_return_amount) AS catalog_return_sum,
        SUM(wr_return_amt) AS web_return_sum,
        (SUM(cr_return_amount) + SUM(wr_return_amt)) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cc_call_center_sk ORDER BY (SUM(cr_return_amount) + SUM(wr_return_amt)) DESC) AS rn
    FROM base_join
    WHERE d_year = 1999
      AND cd_gender = 'F'
      AND wr_reversed_charge > 100
    GROUP BY cc_call_center_sk, cc_name, d_year, cd_gender, hd_income_band_sk
),
filtered_2000 AS (
    SELECT
        cc_call_center_sk,
        cc_name,
        d_year,
        cd_gender,
        hd_income_band_sk,
        SUM(cr_return_amount) AS catalog_return_sum,
        SUM(wr_return_amt) AS web_return_sum,
        (SUM(cr_return_amount) + SUM(wr_return_amt)) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cc_call_center_sk ORDER BY (SUM(cr_return_amount) + SUM(wr_return_amt)) DESC) AS rn
    FROM base_join
    WHERE d_year = 2000
      AND cd_gender = 'M'
      AND wr_reversed_charge > 150
    GROUP BY cc_call_center_sk, cc_name, d_year, cd_gender, hd_income_band_sk
)
SELECT *
FROM (
    SELECT * FROM filtered_1999
    UNION ALL
    SELECT * FROM filtered_2000
) combined
WHERE rn = 1
ORDER BY total_return_amount DESC
LIMIT 100
