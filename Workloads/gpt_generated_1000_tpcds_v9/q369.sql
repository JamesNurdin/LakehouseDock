WITH
  recent_dates AS (
    SELECT d.d_date_sk,
           d.d_date
    FROM date_dim d
    WHERE d.d_year = 2001
  ),
  catalog_sales_filtered AS (
    SELECT
      cs.cs_order_number      AS order_number,
      cs.cs_item_sk           AS item_sk,
      i.i_product_name        AS product_name,
      cs.cs_ext_sales_price   AS ext_sales_price,
      cs.cs_net_profit        AS net_profit,
      d.d_date                AS sale_date
    FROM catalog_sales cs
    JOIN recent_dates d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_sales_price > (
            SELECT AVG(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            JOIN recent_dates d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
          )
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
          )
  ),
  store_sales_filtered AS (
    SELECT
      ss.ss_ticket_number     AS order_number,
      ss.ss_item_sk            AS item_sk,
      i.i_product_name         AS product_name,
      ss.ss_ext_sales_price    AS ext_sales_price,
      ss.ss_net_profit         AS net_profit,
      d.d_date                 AS sale_date
    FROM store_sales ss
    JOIN recent_dates d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_ext_sales_price > (
            SELECT AVG(ss2.ss_ext_sales_price)
            FROM store_sales ss2
            JOIN recent_dates d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
          )
  ),
  combined_sales AS (
    SELECT
      order_number,
      item_sk,
      product_name,
      ext_sales_price,
      net_profit,
      sale_date
    FROM catalog_sales_filtered
    UNION ALL
    SELECT
      order_number,
      item_sk,
      product_name,
      ext_sales_price,
      net_profit,
      sale_date
    FROM store_sales_filtered
  )
SELECT
  cs.order_number,
  cs.item_sk,
  cs.product_name,
  cs.ext_sales_price,
  cs.net_profit,
  cs.sale_date,
  (
    SELECT MAX(cr.cr_return_amount)
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = cs.item_sk
  ) AS max_return_amount
FROM combined_sales cs
WHERE cs.ext_sales_price > (
        SELECT AVG(ext_sales_price)
        FROM combined_sales
      )
ORDER BY cs.net_profit DESC
LIMIT 100
