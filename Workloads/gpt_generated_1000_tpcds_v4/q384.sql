WITH
    d_start AS (SELECT * FROM date_dim),
    d_end AS (SELECT * FROM date_dim),
    d_closed AS (SELECT * FROM date_dim),
    d_extra AS (SELECT * FROM date_dim),
    d_sold2 AS (SELECT * FROM date_dim)
SELECT
    d_start.d_year AS sale_year,
    cc.cc_market_manager,
    i.i_brand,
    cp.cp_department,
    CASE WHEN cc.cc_company = 5 THEN 'Large' ELSE 'Other' END AS company_category,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(ss.ss_coupon_amt) AS avg_coupon_amt,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM date_dim d_start
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN call_center cc
  ON cc.cc_open_date_sk = d_start.d_date_sk
JOIN date_dim d_closed
  ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_extra
  ON cc.cc_closed_date_sk = d_extra.d_date_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_start.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_sold2
  ON ss.ss_sold_date_sk = d_sold2.d_date_sk
JOIN item i2
  ON ss.ss_item_sk = i2.i_item_sk
GROUP BY
    d_start.d_year,
    cc.cc_market_manager,
    i.i_brand,
    cp.cp_department,
    CASE WHEN cc.cc_company = 5 THEN 'Large' ELSE 'Other' END
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
