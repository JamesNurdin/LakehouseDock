WITH base AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_item_sk,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    i.i_brand,
    i.i_category,
    i.i_product_name,
    p.p_promo_name,
    p.p_discount_active,
    w.w_warehouse_name,
    w.w_gmt_offset,
    inv.inv_quantity_on_hand,
    cc.cc_market_manager,
    cr.cr_return_amount,
    cr.cr_net_loss
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE
    ss.ss_ext_sales_price > 1000
    AND ss.ss_quantity >= 2
    AND i.i_current_price BETWEEN 10 AND 500
    AND p.p_discount_active = 'Y'
    AND w.w_gmt_offset BETWEEN -5 AND 5
    AND cc.cc_market_manager LIKE '%Manager%'
)
SELECT
  b.ss_sold_date_sk,
  b.i_brand,
  b.i_category,
  b.w_warehouse_name,
  b.p_promo_name,
  b.ss_quantity,
  b.ss_ext_sales_price,
  b.inv_quantity_on_hand,
  b.cr_return_amount,
  total_sales_by_warehouse,
  RANK() OVER (PARTITION BY b.w_warehouse_name ORDER BY b.ss_ext_sales_price DESC) AS sales_rank,
  CASE
    WHEN b.ss_net_profit > 0 THEN 'PROFITABLE'
    ELSE 'LOSS'
  END AS profit_flag
FROM (
  SELECT
    b.*, 
    SUM(b.ss_ext_sales_price) OVER (PARTITION BY b.w_warehouse_name) AS total_sales_by_warehouse
  FROM base b
  WHERE EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = b.ss_item_sk
      AND cr2.cr_return_amount > 500
  )
) b
ORDER BY b.w_warehouse_name, sales_rank
LIMIT 100
