WITH
  sales_agg AS (
    SELECT
      d_sales.d_date,
      p.p_promo_id,
      SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(cs.cs_net_profit) AS catalog_profit,
      SUM(ss.ss_net_profit) AS store_profit
    FROM catalog_sales cs
    JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
      ON ss.ss_sold_date_sk = d_sales.d_date_sk
      AND ss.ss_promo_sk = p.p_promo_sk
    WHERE d_sales.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 0
      AND ss.ss_quantity > 0
    GROUP BY d_sales.d_date, p.p_promo_id
  ),
  catalog_return_agg AS (
    SELECT
      d_ret.d_date,
      r.r_reason_desc,
      SUM(cr.cr_net_loss) AS catalog_return_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
      AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d_ret.d_year = 2001
      AND cr.cr_return_quantity > 0
    GROUP BY d_ret.d_date, r.r_reason_desc
  ),
  web_return_agg AS (
    SELECT
      d_wr.d_date,
      r.r_reason_desc,
      SUM(wr.wr_net_loss) AS web_return_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d_wr.d_year = 2001
      AND wp.wp_type = 'product'
    GROUP BY d_wr.d_date, r.r_reason_desc
  ),
  inventory_agg AS (
    SELECT
      d_inv.d_date,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    WHERE d_inv.d_year = 2001
      AND inv.inv_quantity_on_hand > 0
    GROUP BY d_inv.d_date
  )
SELECT
  sa.d_date,
  sa.p_promo_id,
  sa.catalog_sales_amount,
  sa.store_sales_amount,
  COALESCE(cra.catalog_return_loss, 0) AS catalog_return_loss,
  COALESCE(wra.web_return_loss, 0) AS web_return_loss,
  inv.total_inventory,
  (COALESCE(cra.catalog_return_loss, 0) + COALESCE(wra.web_return_loss, 0)) AS total_return_loss,
  RANK() OVER (PARTITION BY sa.p_promo_id ORDER BY (COALESCE(cra.catalog_return_loss, 0) + COALESCE(wra.web_return_loss, 0)) DESC) AS loss_rank,
  CASE
    WHEN (COALESCE(cra.catalog_return_loss, 0) + COALESCE(wra.web_return_loss, 0)) > 50000 THEN 'HIGH'
    ELSE 'LOW'
  END AS loss_category,
  (SELECT AVG(catalog_sales_amount) FROM sales_agg) AS avg_catalog_sales_amount
FROM sales_agg sa
LEFT JOIN catalog_return_agg cra
  ON sa.d_date = cra.d_date
LEFT JOIN web_return_agg wra
  ON sa.d_date = wra.d_date
LEFT JOIN inventory_agg inv
  ON sa.d_date = inv.d_date
WHERE sa.catalog_sales_amount > 10000
  AND sa.store_sales_amount > 5000
ORDER BY total_return_loss DESC
LIMIT 100
