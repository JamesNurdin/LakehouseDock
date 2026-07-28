WITH store_return_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2002
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
          WHERE ss.ss_store_sk = s.s_store_sk
            AND d2.d_year = 2002
      )
    GROUP BY s.s_store_id, s.s_store_name
),
catalog_return_agg AS (
    SELECT
        CAST(NULL AS varchar) AS store_id,
        CAST(NULL AS varchar) AS store_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)
SELECT * FROM store_return_agg
UNION ALL
SELECT * FROM catalog_return_agg
LIMIT 100
