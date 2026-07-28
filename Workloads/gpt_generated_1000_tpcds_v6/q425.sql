WITH joined_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price AS catalog_sales,
    ws.ws_ext_sales_price AS web_sales,
    p.p_promo_id,
    d_cs.d_date AS cs_sold_date,
    d_ws.d_date AS ws_ship_date,
    cs.cs_quantity AS catalog_qty,
    ws.ws_quantity AS web_qty
  FROM catalog_sales cs
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN web_sales ws
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
  JOIN date_dim d_ws
    ON ws.ws_ship_date_sk = d_ws.d_date_sk
  WHERE cs.cs_ext_sales_price > 1000
    AND ws.ws_ext_sales_price > 500
    AND p.p_discount_active = 'Y'
    AND d_cs.d_year = 2001
    AND d_ws.d_month_seq BETWEEN 1200 AND 1300
    AND cs.cs_quantity >= 1
    AND ws.ws_quantity >= 1
    AND d_cs.d_quarter_seq = 4
),
agg_sales AS (
  SELECT
    cs_order_number,
    p_promo_id,
    cs_sold_date,
    ws_ship_date,
    (catalog_sales + web_sales) AS total_sales
  FROM joined_sales
)
SELECT
  cs_order_number,
  p_promo_id,
  cs_sold_date,
  ws_ship_date,
  total_sales,
  RANK() OVER (PARTITION BY p_promo_id ORDER BY total_sales DESC) AS sales_rank,
  CASE
    WHEN total_sales > (SELECT AVG(catalog_sales + web_sales) FROM joined_sales)
      THEN 'HIGH'
    ELSE 'NORMAL'
  END AS sales_category
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
