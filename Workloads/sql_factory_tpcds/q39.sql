WITH daily_sales AS (
  SELECT
    i.i_item_id,
    cs.cs_sold_date_sk AS sold_date,
    SUM(cs.cs_quantity) AS qty_sold,
    MAX(p.p_promo_name) AS promo_name,
    AVG(inv.inv_quantity_on_hand) AS avg_on_hand
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = cs.cs_item_sk
    AND inv.inv_date_sk = cs.cs_sold_date_sk
  GROUP BY i.i_item_id, cs.cs_sold_date_sk
),
sales_lags AS (
  SELECT
    ds.i_item_id,
    ds.sold_date,
    ds.qty_sold,
    ds.promo_name,
    ds.avg_on_hand,
    LAG(ds.qty_sold, 1) OVER (PARTITION BY ds.i_item_id ORDER BY ds.sold_date) AS qty_lag1,
    LAG(ds.qty_sold, 2) OVER (PARTITION BY ds.i_item_id ORDER BY ds.sold_date) AS qty_lag2,
    LAG(ds.qty_sold, 3) OVER (PARTITION BY ds.i_item_id ORDER BY ds.sold_date) AS qty_lag3
  FROM daily_sales ds
)
SELECT
  sl.i_item_id,
  sl.sold_date,
  sl.qty_sold,
  sl.promo_name,
  sl.avg_on_hand,
  CASE
    WHEN sl.qty_lag1 IS NOT NULL AND sl.qty_lag2 IS NOT NULL AND sl.qty_lag3 IS NOT NULL
         AND sl.qty_sold < sl.qty_lag1
         AND sl.qty_lag1 < sl.qty_lag2
         AND sl.qty_lag2 < sl.qty_lag3
    THEN 'Decreasing Trend'
    ELSE 'Stable/Increasing'
  END AS sales_trend
FROM sales_lags sl
WHERE sl.qty_lag1 IS NOT NULL
ORDER BY sl.i_item_id, sl.sold_date
LIMIT 100
