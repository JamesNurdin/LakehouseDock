WITH item_sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_ship_mode_sk,
    i.i_manufact_id,
    i.i_category,
    i.i_current_price,
    sm.sm_type,
    inv.inv_quantity_on_hand,
    inv.inv_date_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_reason_sk,
    r.r_reason_desc,
    wp.wp_type
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE i.i_manufact_id IN (630, 364, 479)
    AND inv.inv_quantity_on_hand > 500
    AND sm.sm_type = 'AIR'
)
SELECT
  isales.i_manufact_id,
  isales.i_category,
  isales.sm_type,
  COUNT(DISTINCT isales.cs_order_number) AS orders_cnt,
  SUM(isales.cs_net_paid) AS total_sales,
  AVG(isales.wr_return_amt) AS avg_return_amt,
  MIN(isales.cs_net_paid) AS min_sale,
  MAX(isales.cs_net_paid) AS max_sale,
  CASE WHEN SUM(isales.cs_net_paid) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
  (SELECT MAX(cs2.cs_net_paid) FROM catalog_sales cs2 WHERE cs2.cs_item_sk = isales.cs_item_sk) AS max_item_paid,
  ROW_NUMBER() OVER (ORDER BY SUM(isales.cs_net_paid) DESC) AS rn
FROM item_sales isales
WHERE isales.cs_order_number NOT IN (
    SELECT wr_order_number FROM web_returns WHERE wr_return_quantity > 20
  )
GROUP BY
  isales.i_manufact_id,
  isales.i_category,
  isales.sm_type,
  isales.cs_item_sk
ORDER BY total_sales DESC
LIMIT 100
