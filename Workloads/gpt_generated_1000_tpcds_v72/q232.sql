WITH
  sales_data AS (
    SELECT
      d_sold.d_year               AS year,
      s.s_store_id                AS store_id,
      i.i_category                AS category,
      ws.ws_net_paid              AS amount
    FROM web_sales ws
    JOIN date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN store s
      ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_current_price BETWEEN 20 AND 500
      AND ib.ib_upper_bound <= 150000
      AND s.s_state = 'CA'
  ),
  returns_data AS (
    SELECT
      d_ret.d_year               AS year,
      CAST(NULL AS varchar)      AS store_id,
      i.i_category                AS category,
      -cr.cr_net_loss             AS amount
    FROM catalog_returns cr
    JOIN date_dim d_ret
      ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d_ret.d_year = 2001
      AND i.i_current_price BETWEEN 20 AND 500
      AND ib.ib_upper_bound <= 150000
      AND cp.cp_catalog_number > 5
  ),
  combined AS (
    SELECT year, store_id, category, amount FROM sales_data
    UNION ALL
    SELECT year, store_id, category, amount FROM returns_data
  ),
  agg AS (
    SELECT
      year,
      store_id,
      category,
      SUM(amount) AS net_amount
    FROM combined
    GROUP BY GROUPING SETS (
      (year, store_id, category),
      (year, store_id),
      (year, category),
      (year)
    )
  )
SELECT
  agg.year,
  agg.store_id,
  agg.category,
  agg.net_amount,
  RANK() OVER (PARTITION BY agg.year ORDER BY agg.net_amount DESC) AS rank_by_year,
  (SELECT AVG(i_sub.i_current_price)
     FROM item i_sub
    WHERE i_sub.i_category = agg.category) AS avg_item_price
FROM agg
WHERE NOT EXISTS (
        SELECT 1
          FROM catalog_returns cr_ex
          JOIN item i_ex
            ON cr_ex.cr_item_sk = i_ex.i_item_sk
         WHERE i_ex.i_category = agg.category
           AND cr_ex.cr_return_quantity > 5
      )
ORDER BY agg.year, rank_by_year
LIMIT 100
