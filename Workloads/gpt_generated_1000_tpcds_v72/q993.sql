WITH store_agg AS (
    SELECT
        'STORE' AS source_type,
        s.s_division_id AS division_id,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(sr.sr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(sr.sr_net_loss) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND i.i_item_desc LIKE '%BRUSH%'
      AND t.t_am_pm = 'PM'
    GROUP BY s.s_division_id, r.r_reason_desc
),
web_agg AS (
    SELECT
        'WEB' AS source_type,
        CAST(NULL AS integer) AS division_id,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE
            WHEN SUM(wr.wr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(wr.wr_net_loss) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND i.i_item_desc LIKE '%BRUSH%'
      AND t.t_am_pm = 'PM'
    GROUP BY r.r_reason_desc
)
SELECT source_type,
       division_id,
       reason_desc,
       total_net_loss,
       loss_category
FROM store_agg
UNION ALL
SELECT source_type,
       division_id,
       reason_desc,
       total_net_loss,
       loss_category
FROM web_agg
ORDER BY total_net_loss DESC
LIMIT 100
