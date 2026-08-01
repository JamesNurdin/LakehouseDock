WITH
  inv1 AS (
    SELECT inv_quantity_on_hand,
           inv_item_sk,
           inv_date_sk
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  inv2 AS (
    SELECT inv_quantity_on_hand      AS inv_qty2,
           inv_item_sk               AS inv_item2_sk,
           inv_date_sk               AS inv_date2_sk
    FROM inventory
    WHERE inv_warehouse_sk = 11
  )
SELECT *
FROM (
  (
    SELECT
      d.d_year,
      i.i_category,
      SUM(ws.ws_ext_sales_price)               AS total_web_sales,
      SUM(sr.sr_return_amt)                    AS total_store_returns,
      SUM(wr.wr_return_amt)                    AS total_web_returns,
      SUM(inv1.inv_quantity_on_hand + inv2.inv_qty2) AS total_inventory_qty
    FROM inv1
    JOIN item i ON inv1.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv1.inv_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                           AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                         AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                           AND wr.wr_returned_date_sk = d.d_date_sk
                           AND wr.wr_order_number = ws.ws_order_number
    JOIN inv2 ON inv2.inv_item2_sk = i.i_item_sk
                AND inv2.inv_date2_sk = d.d_date_sk
    WHERE i.i_brand_id = 1
      AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
          AND wr2.wr_returned_date_sk = d.d_date_sk
      )
    GROUP BY CUBE (d.d_year, i.i_category)
  )
  UNION DISTINCT
  (
    SELECT
      d.d_year,
      i.i_category,
      SUM(ws.ws_ext_sales_price)               AS total_web_sales,
      SUM(sr.sr_return_amt)                    AS total_store_returns,
      SUM(wr.wr_return_amt)                    AS total_web_returns,
      SUM(inv1.inv_quantity_on_hand + inv2.inv_qty2) AS total_inventory_qty
    FROM inv1
    JOIN item i ON inv1.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv1.inv_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                           AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                         AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                           AND wr.wr_returned_date_sk = d.d_date_sk
                           AND wr.wr_order_number = ws.ws_order_number
    JOIN inv2 ON inv2.inv_item2_sk = i.i_item_sk
                AND inv2.inv_date2_sk = d.d_date_sk
    WHERE i.i_brand_id = 2
    GROUP BY CUBE (d.d_year, i.i_category)
  )
) AS unioned
INTERSECT
SELECT
  d.d_year,
  i.i_category,
  SUM(ws.ws_ext_sales_price)               AS total_web_sales,
  SUM(sr.sr_return_amt)                    AS total_store_returns,
  SUM(wr.wr_return_amt)                    AS total_web_returns,
  SUM(inv1.inv_quantity_on_hand + inv2.inv_qty2) AS total_inventory_qty
FROM inv1
JOIN item i ON inv1.inv_item_sk = i.i_item_sk
JOIN date_dim d ON inv1.inv_date_sk = d.d_date_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                       AND sr.sr_returned_date_sk = d.d_date_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                       AND wr.wr_returned_date_sk = d.d_date_sk
                       AND wr.wr_order_number = ws.ws_order_number
JOIN inv2 ON inv2.inv_item2_sk = i.i_item_sk
            AND inv2.inv_date2_sk = d.d_date_sk
WHERE i.i_category_id = 5
GROUP BY CUBE (d.d_year, i.i_category)
ORDER BY total_web_sales DESC
