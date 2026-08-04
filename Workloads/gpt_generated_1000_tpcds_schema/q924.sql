/*
   Goal: Identify the top‑selling items (by combined catalog and web return amounts) per product class, enriched with inventory quantities, and label whether catalog or web returns dominate. The query joins all nine TPC‑DS tables, applies several filters, computes a common set of items appearing in both catalog and web returns via INTERSECT, uses a LATERAL subquery to pull inventory totals, ranks items within each class, and finally returns the top‑10 per class split into two UNIONed result sets.
*/
WITH
  /* Join every selected table once so that all tables are referenced */
  joined_all AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      cd.cd_gender,
      cd.cd_marital_status,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      inv.inv_quantity_on_hand,
      i.i_item_sk,
      i.i_product_name,
      i.i_color,
      i.i_class,
      ss.ss_sold_date_sk,
      ss.ss_ext_sales_price,
      wp.wp_web_page_sk,
      wp.wp_max_ad_count,
      wr.wr_return_amt,
      wr.wr_net_loss
    FROM catalog_returns cr
    JOIN item i                     ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd   ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib             ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv              ON i.i_item_sk = inv.inv_item_sk
    JOIN store_sales ss             ON ss.ss_item_sk = i.i_item_sk
    JOIN web_returns wr            ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp                ON wr.wr_web_page_sk = wp.wp_web_page_sk
  ),

  /* Aggregate catalog returns per item */
  item_cr_stats AS (
    SELECT
      i.i_item_sk,
      SUM(cr.cr_return_amount) AS total_cr_return_amount,
      SUM(cr.cr_net_loss)      AS total_cr_net_loss
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  ),

  /* Aggregate web returns per item */
  item_wr_stats AS (
    SELECT
      i.i_item_sk,
      SUM(wr.wr_return_amt) AS total_wr_return_amt,
      SUM(wr.wr_net_loss)   AS total_wr_net_loss
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
  ),

  /* Items that appear in BOTH catalog and web returns */
  common_items AS (
    SELECT i_item_sk FROM item_cr_stats
    INTERSECT
    SELECT i_item_sk FROM item_wr_stats
  ),

  /* Rank items within each class and pull inventory via LATERAL */
  ranked_items AS (
    SELECT
      i.i_item_sk,
      i.i_product_name,
      i.i_color,
      i.i_class,
      COALESCE(crs.total_cr_return_amount, 0) AS cr_return_amt,
      COALESCE(wrs.total_wr_return_amt, 0) AS wr_return_amt,
      CASE
        WHEN COALESCE(crs.total_cr_return_amount, 0) > COALESCE(wrs.total_wr_return_amt, 0)
          THEN 'CatalogHigher'
        ELSE 'WebHigher'
      END AS higher_source,
      ROW_NUMBER() OVER (PARTITION BY i.i_class ORDER BY (COALESCE(crs.total_cr_return_amount, 0) + COALESCE(wrs.total_wr_return_amt, 0)) DESC) AS rn,
      inv_q.inv_quantity_on_hand
    FROM item i
    LEFT JOIN item_cr_stats crs ON i.i_item_sk = crs.i_item_sk
    LEFT JOIN item_wr_stats wrs ON i.i_item_sk = wrs.i_item_sk
    /* LATERAL subquery to fetch total quantity on hand for the current item */
    LEFT JOIN LATERAL (
      SELECT SUM(inv.inv_quantity_on_hand) AS inv_quantity_on_hand
      FROM inventory inv
      WHERE inv.inv_item_sk = i.i_item_sk
    ) inv_q ON TRUE
    WHERE i.i_color IN ('red', 'royal', 'pink')
      AND EXISTS (SELECT 1 FROM common_items ci WHERE ci.i_item_sk = i.i_item_sk)
  )

SELECT
  ri.i_item_sk,
  ri.i_product_name,
  ri.i_color,
  ri.i_class,
  ri.cr_return_amt,
  ri.wr_return_amt,
  ri.higher_source,
  ri.inv_quantity_on_hand
FROM ranked_items ri
WHERE ri.rn <= 5

UNION DISTINCT

SELECT
  ri.i_item_sk,
  ri.i_product_name,
  ri.i_color,
  ri.i_class,
  ri.cr_return_amt,
  ri.wr_return_amt,
  ri.higher_source,
  ri.inv_quantity_on_hand
FROM ranked_items ri
WHERE ri.rn > 5 AND ri.rn <= 10

ORDER BY i_class, cr_return_amt DESC
LIMIT 100
