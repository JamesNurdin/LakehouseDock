/* goal: Combine catalog and web return records for the year 2001 to analyze net loss by return date and reason */
WITH catalog_data AS (
    SELECT d.d_date AS return_date,
           cr.cr_net_loss AS net_loss,
           r.r_reason_desc AS reason_desc
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND cr.cr_net_loss > 0
),
web_data AS (
    SELECT d.d_date AS return_date,
           wr.wr_net_loss AS net_loss,
           r.r_reason_desc AS reason_desc
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND wr.wr_net_loss > 0
)
SELECT return_date,
       net_loss,
       reason_desc
FROM catalog_data
UNION ALL
SELECT return_date,
       net_loss,
       reason_desc
FROM web_data
ORDER BY return_date DESC,
         net_loss DESC
LIMIT 100
