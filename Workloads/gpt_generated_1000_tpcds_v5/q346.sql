WITH
  base AS (
    SELECT
      i.i_category,
      dr.d_year,
      rcd.cd_gender AS refunded_gender,
      SUM(wr.wr_return_amt) AS total_return_amount,
      SUM(wr.wr_return_quantity) AS total_return_quantity,
      COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_quantity,
      AVG(i.i_current_price) AS avg_item_price,
      (
        SELECT MAX(i2.i_current_price)
        FROM tpcds.item i2
        WHERE i2.i_category = i.i_category
      ) AS max_category_price,
      COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM tpcds.web_returns wr
    -- return date
    JOIN tpcds.date_dim dr
      ON wr.wr_returned_date_sk = dr.d_date_sk
    -- item information
    JOIN tpcds.item i
      ON wr.wr_item_sk = i.i_item_sk
    -- refunded customer
    JOIN tpcds.customer rc
      ON wr.wr_refunded_customer_sk = rc.c_customer_sk
    -- returning customer
    JOIN tpcds.customer rcn
      ON wr.wr_returning_customer_sk = rcn.c_customer_sk
    -- refunded customer demographics (different alias)
    JOIN tpcds.customer_demographics rcd
      ON wr.wr_refunded_cdemo_sk = rcd.cd_demo_sk
    -- returning customer demographics (second alias)
    JOIN tpcds.customer_demographics rcd2
      ON wr.wr_returning_cdemo_sk = rcd2.cd_demo_sk
    -- inventory (LEFT to preserve returns without inventory)
    LEFT JOIN tpcds.inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = dr.d_date_sk
    -- inventory date (second date_dim alias)
    LEFT JOIN tpcds.date_dim di
      ON inv.inv_date_sk = di.d_date_sk
    -- call center opened on the return date (first alias)
    LEFT JOIN tpcds.call_center cc
      ON cc.cc_open_date_sk = dr.d_date_sk
    -- call center closed on the return date (second alias)
    LEFT JOIN tpcds.call_center cc_closed
      ON cc_closed.cc_closed_date_sk = dr.d_date_sk
    WHERE dr.d_year = 2001
      AND rcd.cd_gender = 'M'
      AND i.i_category IN ('Sports', 'Books')
      AND EXISTS (
        SELECT 1
        FROM tpcds.call_center cc2
        WHERE cc2.cc_state = 'CA'
          AND cc2.cc_market_manager IS NOT NULL
      )
    GROUP BY i.i_category, dr.d_year, rcd.cd_gender
  )
SELECT *
FROM base
ORDER BY total_return_amount DESC
LIMIT 100
