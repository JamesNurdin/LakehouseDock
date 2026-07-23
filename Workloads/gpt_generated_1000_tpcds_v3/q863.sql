WITH combined AS (
    SELECT d.d_date AS return_date,
           r.r_reason_desc AS reason_desc,
           s.s_store_name AS store_name,
           SUM(sr.sr_net_loss) AS total_net_loss,
           'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND s.s_street_name IN ('Park First', 'College')
      AND r.r_reason_desc LIKE '%color%'
    GROUP BY d.d_date, r.r_reason_desc, s.s_store_name

    UNION ALL

    SELECT d.d_date AS return_date,
           r.r_reason_desc AS reason_desc,
           NULL AS store_name,
           SUM(cr.cr_net_loss) AS total_net_loss,
           'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_id = 'AAAAAAAADBAAAAAA'
    GROUP BY d.d_date, r.r_reason_desc
)
SELECT return_date,
       reason_desc,
       store_name,
       total_net_loss,
       source
FROM combined
ORDER BY return_date DESC,
         total_net_loss DESC
LIMIT 100
