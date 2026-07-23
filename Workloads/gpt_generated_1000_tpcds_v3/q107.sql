WITH center_hourly AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        td.t_hour,
        td.t_sub_shift,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id IN ('AAAAAAAAMAAAAAAA', 'AAAAAAAADAAAAAAA')
    GROUP BY cc.cc_call_center_id, cc.cc_name, td.t_hour, td.t_sub_shift
)
SELECT
    ch.cc_call_center_id,
    ch.cc_name,
    ch.t_hour,
    ch.t_sub_shift,
    ch.total_net_loss,
    ch.return_cnt,
    (ch.total_net_loss / (SELECT SUM(cr2.cr_net_loss) FROM catalog_returns cr2)) * 100 AS pct_of_total_loss
FROM center_hourly ch
WHERE ch.t_sub_shift = 'morning'
UNION ALL
SELECT
    ch.cc_call_center_id,
    ch.cc_name,
    ch.t_hour,
    ch.t_sub_shift,
    ch.total_net_loss,
    ch.return_cnt,
    (ch.total_net_loss / (SELECT SUM(cr2.cr_net_loss) FROM catalog_returns cr2)) * 100 AS pct_of_total_loss
FROM center_hourly ch
WHERE ch.t_sub_shift = 'evening'
ORDER BY pct_of_total_loss DESC
LIMIT 100
