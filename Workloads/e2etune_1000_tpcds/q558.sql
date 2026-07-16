WITH filtered AS (
  SELECT cd.cd_marital_status,
         cd.cd_gender,
         cd.cd_purchase_estimate,
         wp.wp_type,
         wp.wp_link_count
  FROM customer_demographics cd
  JOIN web_page wp
    ON 1 = 1
  WHERE cd.cd_gender = 'F'
    AND cd.cd_purchase_estimate >= 1000
    AND wp.wp_link_count > 10
),
agg AS (
  SELECT cd_marital_status,
         wp_type,
         COUNT(*) AS pair_cnt,
         AVG(cd_purchase_estimate) AS avg_estimate,
         SUM(wp_link_count) AS total_links
  FROM filtered
  GROUP BY cd_marital_status, wp_type
  HAVING COUNT(*) > 5
)
SELECT agg.cd_marital_status,
       agg.wp_type,
       agg.pair_cnt,
       agg.avg_estimate,
       agg.total_links,
       RANK() OVER (PARTITION BY agg.cd_marital_status ORDER BY agg.avg_estimate DESC) AS rank_estimate,
       SUM(agg.total_links) OVER (PARTITION BY agg.cd_marital_status ORDER BY agg.avg_estimate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_links
FROM agg
ORDER BY agg.cd_marital_status, rank_estimate
