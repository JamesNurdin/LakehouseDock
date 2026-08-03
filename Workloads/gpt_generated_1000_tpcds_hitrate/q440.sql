WITH
cs_base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_item_sk,
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_quantity,
    cs.cs_catalog_page_sk,
    cs.cs_bill_addr_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_bill_hdemo_sk
  FROM catalog_sales cs
  WHERE cs.cs_quantity > 0
),
cs_joined AS (
  SELECT
    cs.cs_sold_date_sk,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    cs.cs_item_sk,
    i.i_brand,
    i.i_category,
    cp.cp_department,
    cp.cp_type,
    ca.ca_state,
    cd.cd_gender,
    hd.hd_income_band_sk,
    cs.cs_net_paid,
    cs.cs_quantity,
    cs.cs_order_number,
    cs.cs_catalog_page_sk
  FROM cs_base cs
  LEFT JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  LEFT JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND i.i_current_price BETWEEN 10 AND 100
    AND ca.ca_state IN ('CA','TX')
    AND cd.cd_gender = 'M'
    AND hd.hd_income_band_sk > 5
    AND cp.cp_type = 'promo'
),
cr_joined AS (
  SELECT
    cr.cr_order_number,
    cr.cr_return_amount,
    cr.cr_refunded_cash,
    r.r_reason_desc,
    d_ret.d_year AS ret_year,
    i.i_brand
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  WHERE d_ret.d_year = 2001
),
wr_joined AS (
  SELECT
    wr.wr_item_sk,
    wr.wr_return_amt,
    r.r_reason_desc AS wr_reason,
    d_ret.d_year AS wr_year,
    i.i_brand,
    wp.wp_url
  FROM web_returns wr
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE d_ret.d_year = 2001
    AND wp.wp_type = 'content'
),
intersect_items AS (
  SELECT cs.cs_item_sk FROM cs_joined cs
  INTERSECT
  SELECT wr.wr_item_sk FROM wr_joined wr
),
final_agg AS (
  SELECT
    cp.cp_department,
    i.i_brand,
    d.d_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(wr.wr_return_amt) AS total_web_return_amt
  FROM cs_joined cs
  RIGHT OUTER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN cr_joined cr
    ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN wr_joined wr
    ON cs.cs_item_sk = wr.wr_item_sk
  LEFT JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE EXISTS (
    SELECT 1 FROM intersect_items ii WHERE ii.cs_item_sk = cs.cs_item_sk
  )
  GROUP BY CUBE(cp.cp_department, i.i_brand, d.d_year)
)
SELECT
  cp_department,
  i_brand,
  d_year,
  total_net_paid,
  total_refunded_cash,
  total_web_return_amt,
  RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS dept_brand_rank
FROM final_agg
WHERE (cp_department IS NOT NULL OR i_brand IS NOT NULL)
ORDER BY d_year DESC, dept_brand_rank
LIMIT 100
