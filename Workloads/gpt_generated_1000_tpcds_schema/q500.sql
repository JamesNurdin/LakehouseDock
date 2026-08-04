WITH aggregated_sales AS (
  SELECT
    s.s_store_id,
    r.r_reason_desc,
    td.t_meal_time,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_returns cr ON cr.cr_reason_sk = r.r_reason_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE td.t_am_pm = 'PM'
    AND s.s_state = 'CA'
    AND cd.cd_gender = 'M'
  GROUP BY GROUPING SETS (
    (s.s_store_id, r.r_reason_desc, td.t_meal_time),
    (s.s_store_id, r.r_reason_desc),
    (r.r_reason_desc, td.t_meal_time),
    ()
  )
)
SELECT
  a.s_store_id,
  a.r_reason_desc,
  a.t_meal_time,
  a.total_net_paid,
  a.total_refunded_cash,
  a.num_sales,
  SUM(a.total_net_paid) OVER (
    PARTITION BY a.r_reason_desc
    ORDER BY a.total_net_paid
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_net_paid,
  g.grp
FROM aggregated_sales a
CROSS JOIN (VALUES (1), (2)) AS g (grp)
WHERE a.total_net_paid > 1000

UNION DISTINCT

SELECT
  a.s_store_id,
  a.r_reason_desc,
  a.t_meal_time,
  a.total_net_paid,
  a.total_refunded_cash,
  a.num_sales,
  LEAD(a.total_refunded_cash, 1, 0) OVER (
    PARTITION BY a.r_reason_desc
    ORDER BY a.total_refunded_cash
  ) AS running_net_paid,
  g.grp
FROM aggregated_sales a
CROSS JOIN (VALUES (1), (2)) AS g (grp)
WHERE a.total_refunded_cash > 500

ORDER BY running_net_paid DESC
LIMIT 100
