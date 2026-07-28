WITH joined_data AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_county,
        cp.cp_department,
        cc.cc_name,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND s.s_county IN ('Fairfield County', 'Williamson County')
      AND cd.cd_marital_status = 'M'
      AND cc.cc_mkt_id IN (1, 2, 3)
)
SELECT
    d_year,
    s_store_name,
    s_county,
    cp_department,
    cc_name,
    SUM(wr_return_amt) AS total_return_amount,
    SUM(wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(wr_net_loss) > 10000 THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    RANK() OVER (PARTITION BY s_county ORDER BY SUM(wr_return_amt) DESC) AS return_amount_rank
FROM joined_data
GROUP BY d_year, s_store_name, s_county, cp_department, cc_name
HAVING SUM(wr_return_amt) > 500
ORDER BY s_county, return_amount_rank
LIMIT 100
