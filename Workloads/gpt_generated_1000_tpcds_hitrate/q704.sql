WITH
  -- First branch: catalog returns enriched with many dimensions
  cr_base AS (
    SELECT
      cr.cr_returned_date_sk               AS date_sk,
      cr.cr_item_sk                        AS item_sk,
      cr.cr_refunded_customer_sk           AS customer_sk,
      cr.cr_warehouse_sk                   AS warehouse_sk,
      CAST(NULL AS INTEGER)                AS promo_sk,
      cr.cr_return_amount                  AS amount,
      cr.cr_net_loss                       AS net_loss,
      cr.cr_order_number                   AS order_number,
      cp.cp_department                     AS department,
      i.i_category                         AS category,
      i.i_current_price                    AS price,
      w.w_warehouse_name                   AS warehouse_name,
      r.r_reason_desc                      AS reason_desc,
      d.d_year                             AS year,
      CASE WHEN cr.cr_return_amount > 100 THEN 'HIGH' ELSE 'LOW' END AS flag,
      cd.cd_gender                         AS cd_gender,
      s.s_store_name                       AS store_name
    FROM catalog_returns cr
    JOIN catalog_page cp      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w          ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d           ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN store s              ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  -- Second branch: web sales joined to web returns and promotional data
  ws_wr_base AS (
    SELECT
      ws.ws_sold_date_sk                    AS date_sk,
      ws.ws_item_sk                         AS item_sk,
      ws.ws_bill_customer_sk                AS customer_sk,
      ws.ws_warehouse_sk                    AS warehouse_sk,
      ws.ws_promo_sk                        AS promo_sk,
      ws.ws_ext_sales_price                 AS amount,
      ws.ws_net_profit                      AS net_loss,
      ws.ws_order_number                    AS order_number,
      CAST(NULL AS VARCHAR)                 AS department,
      i.i_category                          AS category,
      i.i_current_price                     AS price,
      w.w_warehouse_name                    AS warehouse_name,
      r.r_reason_desc                       AS reason_desc,
      d.d_year                              AS year,
      CASE WHEN ws.ws_ext_sales_price > 500 THEN 'BIG' ELSE 'SMALL' END AS flag,
      cd.cd_gender                          AS cd_gender,
      s.s_store_name                        AS store_name
    FROM web_sales ws
    JOIN web_returns wr      ON ws.ws_order_number = wr.wr_order_number
                              AND ws.ws_item_sk = wr.wr_item_sk
    JOIN promotion p          ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d           ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w          ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN reason r             ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store s              ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  -- Union the two branches (deduplication)
  combined AS (
    SELECT * FROM cr_base
    UNION DISTINCT
    SELECT * FROM ws_wr_base
  ),

  -- Anti‑join: keep rows that have no matching inventory record for the same item/warehouse/date
  filtered AS (
    SELECT c.*
    FROM combined c
    WHERE NOT EXISTS (
      SELECT 1
      FROM inventory inv
      JOIN date_dim inv_d ON inv.inv_date_sk = inv_d.d_date_sk
      WHERE inv.inv_item_sk = c.item_sk
        AND inv.inv_warehouse_sk = c.warehouse_sk
        AND inv_d.d_year = c.year
    )
  ),

  -- Add window functions (global row number and rank per flag)
  ranked AS (
    SELECT
      f.*,
      ROW_NUMBER() OVER (ORDER BY f.year DESC)                AS rn_global,
      RANK()       OVER (PARTITION BY f.flag ORDER BY f.amount DESC) AS rk_amount
    FROM filtered f
  )
SELECT
  flag,
  year,
  COUNT(*)                              AS cnt,
  SUM(amount)                           AS total_amount,
  AVG(net_loss)                         AS avg_net_loss,
  MAX(rn_global)                        AS max_global_rownum,
  MAX(rk_amount)                        AS max_rank_in_flag
FROM ranked
GROUP BY
  flag,
  year
ORDER BY
  total_amount DESC
LIMIT 100
