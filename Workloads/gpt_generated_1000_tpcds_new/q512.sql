WITH joined_data AS (
   SELECT
      ca.ca_address_sk,
      ca.ca_location_type,
      ca.ca_gmt_offset,
      ca.ca_suite_number,
      sr.sr_return_amt_inc_tax,
      sr.sr_net_loss,
      ss.ss_ext_wholesale_cost,
      ss.ss_net_paid
   FROM store_sales ss
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN store_returns sr
     ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_addr_sk = ca.ca_address_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
   WHERE ss.ss_ext_wholesale_cost > 1000
     AND sr.sr_return_amt_inc_tax > 100
     AND ca.ca_gmt_offset BETWEEN -5 AND 5
),
expanded AS (
   SELECT
      jd.*, 
      suite_part
   FROM joined_data jd
   CROSS JOIN UNNEST(split(jd.ca_suite_number, ' ')) AS t(suite_part)
),
agg1 AS (
   SELECT
      CASE 
         WHEN ca_location_type = 'single family' THEN 'SF'
         WHEN ca_location_type = 'apartment'      THEN 'APT'
         ELSE 'OTHER'
      END AS loc_category,
      suite_part,
      SUM(sr_net_loss) AS total_net_loss,
      AVG(ss_net_paid) AS avg_net_paid
   FROM expanded
   GROUP BY
      CASE 
         WHEN ca_location_type = 'single family' THEN 'SF'
         WHEN ca_location_type = 'apartment'      THEN 'APT'
         ELSE 'OTHER'
      END,
      suite_part
),
subq1 AS (
   SELECT loc_category, suite_part, total_net_loss
   FROM agg1
   WHERE total_net_loss > 500
),
subq2 AS (
   SELECT loc_category, suite_part, total_net_loss
   FROM agg1
   WHERE avg_net_paid > 200
),
unioned AS (
   SELECT loc_category, suite_part, total_net_loss FROM subq1
   UNION DISTINCT
   SELECT loc_category, suite_part, total_net_loss FROM subq2
),
subq3 AS (
   SELECT loc_category, suite_part
   FROM agg1
   WHERE total_net_loss BETWEEN 400 AND 600
),
subq4 AS (
   SELECT loc_category, suite_part
   FROM agg1
   WHERE avg_net_paid BETWEEN 150 AND 300
),
intersected_keys AS (
   SELECT loc_category, suite_part FROM subq3
   INTERSECT
   SELECT loc_category, suite_part FROM subq4
)
SELECT
   u.loc_category,
   u.suite_part,
   u.total_net_loss,
   a.avg_net_paid
FROM unioned u
JOIN intersected_keys ik
  ON u.loc_category = ik.loc_category
 AND u.suite_part = ik.suite_part
JOIN agg1 a
  ON a.loc_category = u.loc_category
 AND a.suite_part = u.suite_part
ORDER BY u.total_net_loss DESC
LIMIT 100
