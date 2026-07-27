WITH store_agg AS (
   SELECT
      r.r_reason_desc,
      cd.cd_gender,
      SUM(sr.sr_net_loss) AS total_net_loss
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
   WHERE cd.cd_dep_employed_count > 0
     AND r.r_reason_id IN ('AAAAAAAAPAAAAAAA', 'AAAAAAABBAAAAAA')
   GROUP BY r.r_reason_desc, cd.cd_gender
),
web_agg AS (
   SELECT
      r.r_reason_desc,
      cd.cd_gender,
      SUM(wr.wr_net_loss) AS total_net_loss
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_dep_employed_count > 0
     AND r.r_reason_id IN ('AAAAAAAAPAAAAAAA', 'AAAAAAABBAAAAAA')
   GROUP BY r.r_reason_desc, cd.cd_gender
),
combined AS (
   SELECT 'store' AS source, r_reason_desc, cd_gender, total_net_loss
   FROM store_agg
   UNION ALL
   SELECT 'web' AS source, r_reason_desc, cd_gender, total_net_loss
   FROM web_agg
)
SELECT
   source,
   r_reason_desc,
   cd_gender,
   total_net_loss,
   ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_net_loss DESC) AS rn
FROM combined
ORDER BY total_net_loss DESC
LIMIT 100
