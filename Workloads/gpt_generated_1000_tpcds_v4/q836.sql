WITH catalog_agg AS (
   SELECT r.r_reason_desc AS reason_desc,
          sm.sm_type AS ship_type,
          SUM(cr.cr_net_loss) AS total_net_loss,
          COUNT(*) AS cnt_returns
   FROM catalog_returns cr
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_vehicle_count >= 0
   GROUP BY r.r_reason_desc, sm.sm_type
),
web_agg AS (
   SELECT r.r_reason_desc AS reason_desc,
          sm.sm_type AS ship_type,
          SUM(wr.wr_net_loss) AS total_net_loss,
          COUNT(*) AS cnt_returns
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_dep_count > 1
   GROUP BY r.r_reason_desc, sm.sm_type
)
SELECT reason_desc,
       ship_type,
       SUM(total_net_loss) AS combined_net_loss,
       SUM(cnt_returns) AS combined_returns
FROM (
   SELECT DISTINCT reason_desc, ship_type, total_net_loss, cnt_returns FROM catalog_agg
   UNION ALL
   SELECT DISTINCT reason_desc, ship_type, total_net_loss, cnt_returns FROM web_agg
) u
GROUP BY reason_desc, ship_type
ORDER BY combined_net_loss DESC
LIMIT 20
