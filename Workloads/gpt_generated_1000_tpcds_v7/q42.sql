WITH total_returns_by_order AS (
   SELECT cr_order_number,
          SUM(cr_return_amount) AS total_ret_amount
   FROM catalog_returns
   GROUP BY cr_order_number
)
SELECT
   cs.cs_order_number,
   cc.cc_name,
   p.p_promo_name,
   sm.sm_type,
   dd_sold.d_year,
   dd_sold.d_month_seq,
   ws.web_name,
   cs.cs_net_paid,
   cr.cr_return_amount,
   (cs.cs_net_paid - COALESCE(cr.cr_return_amount, 0)) AS net_after_returns,
   total_returns_by_order.total_ret_amount,
   ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY cs.cs_net_paid DESC) AS sales_rank_in_center,
   SUM(cs.cs_net_paid) OVER (PARTITION BY cc.cc_call_center_sk ORDER BY dd_sold.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_center_sales
FROM catalog_sales cs
JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
 AND cs.cs_item_sk = cr.cr_item_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim dd_sold
  ON cs.cs_sold_date_sk = dd_sold.d_date_sk
JOIN date_dim dd_ship
  ON cs.cs_ship_date_sk = dd_ship.d_date_sk
JOIN date_dim dd_cc_open
  ON cc.cc_open_date_sk = dd_cc_open.d_date_sk
JOIN date_dim dd_cc_close
  ON cc.cc_closed_date_sk = dd_cc_close.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = dd_sold.d_date_sk
LEFT JOIN total_returns_by_order
  ON cs.cs_order_number = total_returns_by_order.cr_order_number
WHERE dd_sold.d_year = 2001
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND EXISTS (
        SELECT 1
        FROM reason r2
        WHERE r2.r_reason_sk = cr.cr_reason_sk
          AND r2.r_reason_desc LIKE '%damage%'
      )
ORDER BY net_after_returns DESC
LIMIT 100
