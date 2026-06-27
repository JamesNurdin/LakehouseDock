/*
  Analytical query: Net loss by return reason across catalog and web channels.
  Shows total net loss, contribution of each channel, percentage of overall loss,
  and a rank ordered by total loss (top 10 reasons).
*/
WITH catalog_agg AS (
    SELECT r.r_reason_desc,
           SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
),
web_agg AS (
    SELECT r.r_reason_desc,
           SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_desc
),
combined AS (
    SELECT COALESCE(c.r_reason_desc, w.r_reason_desc) AS reason_desc,
           c.catalog_net_loss,
           w.web_net_loss
    FROM catalog_agg c
    FULL OUTER JOIN web_agg w
      ON c.r_reason_desc = w.r_reason_desc
),
final_agg AS (
    SELECT reason_desc,
           COALESCE(catalog_net_loss, 0) AS catalog_net_loss,
           COALESCE(web_net_loss, 0) AS web_net_loss,
           COALESCE(catalog_net_loss, 0) + COALESCE(web_net_loss, 0) AS total_net_loss
    FROM combined
)
SELECT reason_desc,
       catalog_net_loss,
       web_net_loss,
       total_net_loss,
       ROUND(100.0 * total_net_loss / SUM(total_net_loss) OVER (), 2) AS pct_of_total,
       ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM final_agg
ORDER BY total_net_loss DESC
LIMIT 10
