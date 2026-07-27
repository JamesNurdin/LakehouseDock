WITH store_ret AS (
    SELECT
        'store' AS return_type,
        d.d_date AS return_date,
        s.s_store_name,
        r.r_reason_desc,
        sr.sr_net_loss,
        CASE WHEN sr.sr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_start_date_sk <= d.d_date_sk
            AND p.p_end_date_sk >= d.d_date_sk
            AND p.p_item_sk = sr.sr_item_sk
      )
),
web_ret AS (
    SELECT
        'web' AS return_type,
        d.d_date AS return_date,
        CAST(NULL AS varchar) AS s_store_name,
        r.r_reason_desc,
        wr.wr_net_loss,
        CASE WHEN wr.wr_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_start_date_sk <= d.d_date_sk
            AND p.p_end_date_sk >= d.d_date_sk
            AND p.p_item_sk = wr.wr_item_sk
      )
)
SELECT *
FROM store_ret
UNION ALL
SELECT *
FROM web_ret
LIMIT 100
