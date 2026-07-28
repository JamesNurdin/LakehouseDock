WITH catalog_ret AS (
    SELECT
        d.d_year AS return_year,
        r.r_reason_desc AS reason,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY d.d_year, r.r_reason_desc
),
store_ret AS (
    SELECT
        d.d_year AS return_year,
        r.r_reason_desc AS reason,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%defective%'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = sr.sr_item_sk
            AND p.p_discount_active = 'Y'
            AND p.p_start_date_sk <= d.d_date_sk
            AND p.p_end_date_sk >= d.d_date_sk
      )
    GROUP BY d.d_year, r.r_reason_desc
)
SELECT *
FROM catalog_ret
UNION ALL
SELECT *
FROM store_ret
ORDER BY return_year ASC, total_net_loss DESC
LIMIT 100
