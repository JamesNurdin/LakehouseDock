WITH joined AS (
  SELECT
    d1.d_year,
    i.i_category,
    i.i_item_id,
    w.web_site_id,
    w.web_country,
    ss.ss_net_paid,
    ss.ss_ext_discount_amt,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_order_number,
    r.r_reason_desc,
    CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_amount_category,
    (SELECT avg(ss2.ss_quantity)
       FROM store_sales ss2
      WHERE ss2.ss_item_sk = ss.ss_item_sk) AS avg_item_quantity
  FROM store_sales ss
  JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
  JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
  JOIN time_dim t2 ON cr.cr_returned_time_sk = t2.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN web_site w ON w.web_open_date_sk = d1.d_date_sk
  WHERE d1.d_year = 2001
    AND i.i_category = 'Shoes'
    AND w.web_country = 'United States'
    AND EXISTS (
          SELECT 1
            FROM store_sales ss2
           WHERE ss2.ss_customer_sk = c.c_customer_sk
             AND ss2.ss_net_paid > 5000
        )
)
SELECT
  d_year,
  i_category,
  web_site_id,
  return_amount_category,
  SUM(ss_net_paid) AS total_sales,
  SUM(cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT cr_order_number) AS return_orders,
  AVG(cr_return_quantity) AS avg_return_quantity,
  AVG(avg_item_quantity) AS avg_item_quantity_over_group,
  RANK() OVER (ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
FROM joined
GROUP BY
  d_year,
  i_category,
  web_site_id,
  return_amount_category
HAVING SUM(ss_net_paid) > 10000
ORDER BY total_sales DESC
LIMIT 100
