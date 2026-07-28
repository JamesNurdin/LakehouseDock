WITH joined_data AS (
  SELECT DISTINCT
    d.d_year,
    d.d_date_sk,
    i.i_category,
    ca.ca_state,
    cc.cc_name,
    s.s_store_name,
    w.w_warehouse_name,
    p.p_promo_name,
    r.r_reason_desc,
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_quantity,
    cr.cr_net_loss,
    ws.ws_net_paid,
    ws.ws_quantity,
    wr.wr_net_loss,
    ib.ib_upper_bound
  FROM
    date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE
    d.d_year = 2001
    AND i.i_current_price BETWEEN 20 AND 150
    AND cc.cc_state = 'CA'
    AND w.w_state = 'CA'
    AND ib.ib_upper_bound > 50000
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'M'
),
prepared AS (
  SELECT
    d_year,
    i_category,
    ca_state,
    cs_order_number,
    (cs_net_paid + ws_net_paid - cr_net_loss - wr_net_loss) AS total_net,
    (cs_quantity + ws_quantity) / 2.0 AS avg_qty
  FROM joined_data
  WHERE (cs_net_paid + ws_net_paid - cr_net_loss - wr_net_loss) > 0
)
SELECT
  jd.d_year,
  jd.i_category,
  jd.ca_state,
  SUM(jd.total_net) AS sum_total_net,
  COUNT(DISTINCT jd.cs_order_number) AS distinct_orders,
  AVG(jd.avg_qty) AS avg_qty,
  (SELECT SUM(cs2.cs_net_paid)
   FROM catalog_sales cs2
   JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
   WHERE d2.d_year = jd.d_year) AS year_net_paid
FROM prepared jd
GROUP BY GROUPING SETS (
  (d_year, i_category, ca_state),
  (d_year, i_category),
  (d_year),
  ()
)
HAVING SUM(jd.total_net) > 1000
ORDER BY jd.d_year DESC, jd.i_category, sum_total_net DESC
LIMIT 100
