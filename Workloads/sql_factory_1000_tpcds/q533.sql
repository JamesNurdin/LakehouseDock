WITH hourly_sales AS (
  SELECT ws.ws_sold_date_sk,
    t.t_hour,
    i.i_brand,
    i.i_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_qty,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS total_promo_cost
  FROM web_sales ws
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY ws.ws_sold_date_sk, t.t_hour, i.i_brand, i.i_category
),
ranked_hours AS (
  SELECT hs.*, ROW_NUMBER() OVER (PARTITION BY hs.ws_sold_date_sk ORDER BY hs.total_sales DESC) AS hour_rank,
    DENSE_RANK() OVER (PARTITION BY hs.ws_sold_date_sk ORDER BY hs.total_sales DESC) AS sales_dense_rank
  FROM hourly_sales hs
)
SELECT rh.ws_sold_date_sk,
  rh.t_hour,
  rh.i_brand,
  rh.i_category,
  rh.total_sales,
  rh.total_qty,
  rh.orders,
  rh.total_promo_cost,
  CASE WHEN rh.t_hour BETWEEN 6 AND 11 THEN 'Morning'
       WHEN rh.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
       WHEN rh.t_hour BETWEEN 18 AND 23 THEN 'Evening'
       ELSE 'Night' END AS time_of_day,
  rh.hour_rank,
  rh.sales_dense_rank
FROM ranked_hours rh
WHERE rh.hour_rank <= 3
ORDER BY rh.ws_sold_date_sk, rh.total_sales DESC
LIMIT 100
