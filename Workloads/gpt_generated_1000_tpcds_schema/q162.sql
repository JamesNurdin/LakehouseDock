WITH base AS (
  SELECT
    cc.cc_name,
    d.d_year,
    i.i_brand,
    r.r_reason_desc,
    cs.cs_net_paid,
    wr.wr_net_loss,
    cs.cs_order_number,
    i.i_current_price
  FROM tpcds.call_center cc
  LEFT JOIN tpcds.catalog_sales cs
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
  LEFT JOIN tpcds.customer cu
    ON cs.cs_bill_customer_sk = cu.c_customer_sk
  LEFT JOIN tpcds.date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
  FULL OUTER JOIN tpcds.web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
  LEFT JOIN tpcds.reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE cc.cc_zip = '74593'
    AND d.d_year = 2001
    AND i.i_color = 'Red'
    AND r.r_reason_desc = 'duplicate purchase'
    AND cu.c_salutation = 'Ms.'
)
SELECT
  cc_name,
  d_year,
  i_brand,
  r_reason_desc,
  SUM(cs_net_paid) AS total_sales,
  SUM(wr_net_loss) AS total_loss,
  COUNT(DISTINCT cs_order_number) AS order_cnt,
  AVG(i_current_price) AS avg_price
FROM base
GROUP BY
  cc_name,
  d_year,
  i_brand,
  r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
