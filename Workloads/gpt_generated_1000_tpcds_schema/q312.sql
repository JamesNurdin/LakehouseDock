WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    d_sold.d_year,
    cs.cs_quantity,
    cs.cs_net_paid,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_income_band_sk,
    ca.ca_state,
    cc.cc_name,
    cp.cp_department,
    w.w_warehouse_name,
    r.r_reason_desc,
    t_sold.t_hour,
    wp.wp_url,
    ws.web_name
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year BETWEEN 1999 AND 2001
    AND cs.cs_quantity > 5
    AND wp.wp_autogen_flag = 'Y'
),
agg_a AS (
  SELECT
    c_customer_id,
    cd_gender,
    d_year,
    SUM(cs_net_paid) AS total_net_paid
  FROM base
  GROUP BY c_customer_id, cd_gender, d_year
),
agg_b AS (
  SELECT
    c_customer_id,
    cd_gender,
    d_year,
    SUM(cs_net_paid) AS total_net_paid
  FROM base
  WHERE cs_quantity < 10
  GROUP BY c_customer_id, cd_gender, d_year
),
intersected AS (
  SELECT * FROM agg_a
  INTERSECT
  SELECT * FROM agg_b
),
ranked AS (
  SELECT
    c_customer_id,
    cd_gender,
    d_year,
    total_net_paid,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS revenue_rank
  FROM intersected
),
rollup_totals AS (
  SELECT
    cd_gender,
    d_year,
    SUM(total_net_paid) AS subtotal_net_paid
  FROM ranked
  GROUP BY ROLLUP (cd_gender, d_year)
)
SELECT
  ranked.cd_gender,
  ranked.d_year,
  rollup_totals.subtotal_net_paid,
  ranked.revenue_rank
FROM ranked
FULL OUTER JOIN rollup_totals
  ON ranked.cd_gender = rollup_totals.cd_gender
 AND ranked.d_year = rollup_totals.d_year
ORDER BY ranked.d_year DESC, rollup_totals.subtotal_net_paid DESC
LIMIT 100
