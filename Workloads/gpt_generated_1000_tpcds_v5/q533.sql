WITH jan_returns AS (
    SELECT
        cc.cc_name AS call_center_name,
        d.d_date AS return_date,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-01-31'
      AND t.t_hour BETWEEN 0 AND 11
    GROUP BY cc.cc_name, d.d_date
), feb_returns AS (
    SELECT
        cc.cc_name AS call_center_name,
        d.d_date AS return_date,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-02-01' AND DATE '2001-02-28'
      AND i.i_category = 'Sports'
      AND t.t_hour BETWEEN 0 AND 11
    GROUP BY cc.cc_name, d.d_date
)
SELECT * FROM jan_returns
UNION ALL
SELECT * FROM feb_returns
ORDER BY total_return_amount DESC
LIMIT 100
