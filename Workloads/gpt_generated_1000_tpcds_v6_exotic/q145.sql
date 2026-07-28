WITH inv_cte AS (
   SELECT inv_date_sk, inv_item_sk, inv_quantity_on_hand
   FROM inventory
   WHERE inv_quantity_on_hand > 0
),
promo_avg AS (
   SELECT ws.ws_promo_sk AS p_promo_sk, AVG(ws.ws_ext_discount_amt) AS avg_disc
   FROM web_sales ws
   GROUP BY ws.ws_promo_sk
)
SELECT
   c.c_customer_id,
   i.i_item_id,
   d.d_year,
   SUM(ws.ws_net_paid)                         AS total_net_paid,
   COUNT(DISTINCT ws.ws_order_number)          AS order_cnt,
   AVG(ws.ws_ext_discount_amt)                AS avg_discount,
   SUM(COALESCE(wr.wr_return_quantity, 0))    AS total_web_return_qty,
   SUM(COALESCE(sr.sr_return_quantity, 0))    AS total_store_return_qty,
   MAX(ws.ws_sales_price)                     AS max_sales_price,
   MIN(i.i_current_price)                     AS min_item_price
FROM web_sales ws
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
LEFT JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
 AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN inv_cte inv
  ON inv.inv_date_sk = d.d_date_sk
 AND inv.inv_item_sk = i.i_item_sk
WHERE cd.cd_credit_rating = 'Good'
  AND cd.cd_purchase_estimate >= 5000
  AND i.i_current_price BETWEEN 20 AND 200
  AND d.d_year = 2002
  AND hd.hd_buy_potential = '500-1000'
  AND ib.ib_lower_bound >= 50000
  AND ws.ws_net_paid > 1000
  AND we.web_country = 'United States'
  AND ws.ws_ext_discount_amt > (
        SELECT pa.avg_disc
        FROM promo_avg pa
        WHERE pa.p_promo_sk = ws.ws_promo_sk
      )
  AND EXISTS (
        SELECT 1
        FROM inventory inv2
        WHERE inv2.inv_item_sk = i.i_item_sk
          AND inv2.inv_quantity_on_hand > 10
      )
GROUP BY GROUPING SETS (
        (c.c_customer_id, i.i_item_id, d.d_year),
        (c.c_customer_id, d.d_year),
        (i.i_item_id, d.d_year)
      )
ORDER BY total_net_paid DESC
LIMIT 100
