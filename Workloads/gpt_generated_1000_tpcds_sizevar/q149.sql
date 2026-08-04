(
  SELECT p.p_promo_id,
         d.d_year AS fy_year
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d.d_fy_year = 1913
    AND p.p_discount_active = 'Y'
  GROUP BY p.p_promo_id, d.d_year
  HAVING sum(cs.cs_ext_sales_price) > 1000
)
UNION
(
  SELECT p.p_promo_id,
         d.d_year AS fy_year
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_weekend = 'Y'
    AND p.p_channel_tv = 'Y'
  GROUP BY p.p_promo_id, d.d_year
  HAVING sum(ws.ws_ext_sales_price) > 500
)
EXCEPT
(
  SELECT p.p_promo_id,
         d.d_year AS fy_year
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY p.p_promo_id, d.d_year
)
ORDER BY p_promo_id,
         fy_year
LIMIT 100
