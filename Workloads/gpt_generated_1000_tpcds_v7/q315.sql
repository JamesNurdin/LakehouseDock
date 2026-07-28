WITH returns_by_page AS (
    SELECT
        cp.cp_catalog_number,
        d.d_year,
        COUNT(sr.sr_ticket_number) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_reversed_charge) AS avg_reversed_charge
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cp.cp_type = 'monthly'
      AND cd.cd_education_status = 'Advanced Degree'
      AND sr.sr_reversed_charge > 10
      AND ws.web_state = 'CA'
    GROUP BY cp.cp_catalog_number, d.d_year
)
SELECT
    AVG(total_return_amt) AS avg_total_return_amt,
    SUM(return_cnt) AS sum_return_cnt
FROM returns_by_page
LIMIT 100
