WITH sub1 AS (
  SELECT
    s.s_store_id,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank,
    CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
  FROM store s
  JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
  JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND ib.ib_lower_bound >= 30000
    AND cs.cs_quantity > 5
  GROUP BY s.s_store_id, d.d_year
),
sub2 AS (
  SELECT
    s.s_store_id,
    d.d_year,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank,
    CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High' ELSE 'Low' END AS profit_category
  FROM store s
  JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_store_sk = s.s_store_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
  JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
  JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
    AND ib.ib_lower_bound >= 30000
    AND cs.cs_quantity > 10
  GROUP BY s.s_store_id, d.d_year
)
SELECT *
FROM sub1
INTERSECT
SELECT *
FROM sub2
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
