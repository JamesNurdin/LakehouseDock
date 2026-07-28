WITH
  cr_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      SUM(cr.cr_net_loss) AS cr_total_loss
    FROM catalog_returns cr
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
  ),
  wr_agg AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_returned_date_sk,
      SUM(wr.wr_net_loss) AS wr_total_loss
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    GROUP BY wr.wr_item_sk, wr.wr_returned_date_sk
  ),
  reason_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      MAX(r.r_reason_desc) AS reason_desc
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY cr.cr_item_sk, cr.cr_returned_date_sk
  ),
  sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_promo_sk,
      ws.ws_ship_mode_sk,
      ws.ws_web_page_sk,
      ws.ws_bill_customer_sk,
      ws.ws_bill_cdemo_sk
    FROM web_sales ws
  )
SELECT
  d.d_year,
  i.i_item_id,
  i.i_brand,
  i.i_category,
  p.p_promo_name,
  sm.sm_type,
  SUM(s.ws_ext_sales_price)                         AS total_sales,
  SUM(COALESCE(cr_agg.cr_total_loss, 0) + COALESCE(wr_agg.wr_total_loss, 0)) AS total_return_loss,
  COUNT(DISTINCT s.ws_order_number)                AS order_cnt,
  RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(COALESCE(cr_agg.cr_total_loss, 0) + COALESCE(wr_agg.wr_total_loss, 0)) DESC) AS loss_rank,
  COALESCE(reason_agg.reason_desc, 'UNKNOWN')       AS return_reason
FROM sales s
JOIN date_dim d        ON s.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t        ON s.ws_sold_time_sk = t.t_time_sk
JOIN item i            ON s.ws_item_sk = i.i_item_sk
JOIN customer c        ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON s.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p       ON s.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm     ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp       ON s.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN store st      ON st.s_closed_date_sk = d.d_date_sk
LEFT JOIN cr_agg       ON cr_agg.cr_item_sk = i.i_item_sk AND cr_agg.cr_returned_date_sk = d.d_date_sk
LEFT JOIN wr_agg       ON wr_agg.wr_item_sk = i.i_item_sk AND wr_agg.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason_agg   ON reason_agg.cr_item_sk = i.i_item_sk AND reason_agg.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND i.i_current_price > 10
  AND sm.sm_type = 'AIR'
  AND t.t_am_pm = 'PM'
  AND p.p_discount_active = 'N'
  AND NOT EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY
  d.d_year,
  i.i_item_id,
  i.i_brand,
  i.i_category,
  p.p_promo_name,
  sm.sm_type,
  reason_agg.reason_desc
HAVING SUM(COALESCE(cr_agg.cr_total_loss, 0) + COALESCE(wr_agg.wr_total_loss, 0)) > 1000
ORDER BY d.d_year, loss_rank
