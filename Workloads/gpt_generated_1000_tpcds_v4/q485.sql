WITH cs_agg AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_item_sk,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_ext_sales_price) AS total_ext_sales,
            COUNT(*) AS cnt_sales
        FROM catalog_sales cs
        GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk
    ),
    sr_agg AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_item_sk,
            SUM(sr.sr_return_amt) AS total_return_amt,
            COUNT(*) AS cnt_returns
        FROM store_returns sr
        GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
    )
SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    sm.sm_type,
    r.r_reason_desc,
    ws.web_name,
    wp.wp_type,
    ib.ib_lower_bound,
    SUM(cs_agg.total_net_paid) AS sum_net_paid,
    SUM(cs_agg.total_ext_sales) AS sum_ext_sales,
    SUM(sr_agg.total_return_amt) AS sum_return_amt,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    AVG(cs.cs_sales_price) AS avg_sales_price
FROM cs_agg
JOIN catalog_sales cs
      ON cs.cs_sold_date_sk = cs_agg.cs_sold_date_sk
     AND cs.cs_item_sk = cs_agg.cs_item_sk
JOIN store_sales ss
      ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
     AND ss.ss_item_sk = cs.cs_item_sk
JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk = ss.ss_item_sk
JOIN sr_agg
      ON sr_agg.sr_returned_date_sk = sr.sr_returned_date_sk
     AND sr_agg.sr_item_sk = sr.sr_item_sk
JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
JOIN call_center cc
      ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN ship_mode sm
      ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN warehouse w
      ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN reason r
      ON r.r_reason_sk = cr.cr_reason_sk
JOIN date_dim d
      ON d.d_date_sk = cs.cs_sold_date_sk
JOIN time_dim t
      ON t.t_time_sk = cs.cs_sold_time_sk
JOIN customer_demographics cd
      ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd
      ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN income_band ib
      ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_month_seq BETWEEN 1200 AND 1300
  AND cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc LIKE '%Damaged%'
  AND ws.web_country = 'United States'
  AND ib.ib_lower_bound >= 50000
GROUP BY
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    sm.sm_type,
    r.r_reason_desc,
    ws.web_name,
    wp.wp_type,
    ib.ib_lower_bound
ORDER BY sum_net_paid DESC
LIMIT 100
