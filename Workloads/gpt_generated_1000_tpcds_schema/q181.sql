WITH
  -- Base query joining all tables with explicit joins and multiple aliases of date_dim
  base AS (
    SELECT
      ss.ss_item_sk               AS item_sk,
      ss.ss_store_sk              AS store_sk,
      d_sales.d_year              AS year,
      ss.ss_sales_price           AS sales_price,
      inv.inv_quantity_on_hand    AS quantity_on_hand,
      cr.cr_return_amount         AS return_amount,
      cr.cr_net_loss              AS net_loss,
      p_sales.p_promo_name        AS promo_name,
      d_promo_start.d_year        AS promo_start_year,
      d_promo_end.d_year          AS promo_end_year,
      r_cr.r_reason_desc          AS return_reason_desc,
      wr.wr_return_amt            AS web_return_amount,
      wr.wr_net_loss              AS web_net_loss,
      r_wr.r_reason_desc          AS web_return_reason_desc
    FROM store_sales ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk                                      -- join 1
    LEFT JOIN promotion p_sales
      ON ss.ss_promo_sk = p_sales.p_promo_sk                                          -- join 2
    LEFT JOIN date_dim d_promo_start
      ON p_sales.p_start_date_sk = d_promo_start.d_date_sk                            -- join 3
    LEFT JOIN date_dim d_promo_end
      ON p_sales.p_end_date_sk = d_promo_end.d_date_sk                                -- join 4
    LEFT JOIN date_dim d_inv
      ON ss.ss_sold_date_sk = d_inv.d_date_sk                                          -- join 5 (date_dim reused)
    LEFT JOIN inventory inv
      ON inv.inv_date_sk = d_inv.d_date_sk
     AND inv.inv_item_sk = ss.ss_item_sk                                            -- join 6
    LEFT JOIN date_dim d_cr
      ON ss.ss_sold_date_sk = d_cr.d_date_sk                                           -- join 7 (date_dim reused)
    LEFT JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d_cr.d_date_sk
     AND cr.cr_item_sk = ss.ss_item_sk                                             -- join 8
    LEFT JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk                                          -- join 9
    LEFT JOIN date_dim d_wr
      ON ss.ss_sold_date_sk = d_wr.d_date_sk                                           -- join 10 (date_dim reused)
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d_wr.d_date_sk
     AND wr.wr_item_sk = ss.ss_item_sk                                            -- join 11
    LEFT JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk                                          -- join 12
  ),

  -- Second query using a FULL OUTER JOIN between inventory and catalog_returns
  full_inv_cr AS (
    SELECT
      ss.ss_item_sk               AS item_sk,
      ss.ss_store_sk              AS store_sk,
      d_sales.d_year              AS year,
      ss.ss_sales_price           AS sales_price,
      inv.inv_quantity_on_hand    AS quantity_on_hand,
      cr.cr_return_amount         AS return_amount,
      cr.cr_net_loss              AS net_loss
    FROM store_sales ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk                                      -- join 13
    FULL OUTER JOIN inventory inv
      ON inv.inv_date_sk = d_sales.d_date_sk
     AND inv.inv_item_sk = ss.ss_item_sk                                            -- join 14 (FULL)
    FULL OUTER JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d_sales.d_date_sk
     AND cr.cr_item_sk = ss.ss_item_sk                                            -- join 15 (FULL)
  )

SELECT
  item_sk,
  store_sk,
  year,
  SUM(sales_price)          AS total_sales_price,
  SUM(quantity_on_hand)    AS total_quantity_on_hand,
  SUM(return_amount)       AS total_return_amount,
  SUM(net_loss)             AS total_net_loss
FROM (
  SELECT
    item_sk,
    store_sk,
    year,
    sales_price,
    quantity_on_hand,
    return_amount,
    net_loss
  FROM base

  UNION DISTINCT

  SELECT
    item_sk,
    store_sk,
    year,
    sales_price,
    quantity_on_hand,
    return_amount,
    net_loss
  FROM full_inv_cr
) AS combined
GROUP BY
  item_sk,
  store_sk,
  year
ORDER BY
  total_sales_price DESC
LIMIT 100
