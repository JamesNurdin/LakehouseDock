WITH
  distinct_sites AS (
    SELECT DISTINCT web_name
    FROM web_site
    WHERE web_name LIKE '%Shop%'
  ),
  sales_filtered AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_ext_discount_amt,
      ws.ws_net_profit,
      d.d_date,
      i.i_product_name,
      ws.ws_ext_wholesale_cost,
      wsite.web_name,
      CONCAT(i.i_product_name, ' - ', CAST(ws.ws_quantity AS varchar)) AS product_qty_desc,
      CASE
        WHEN regexp_like(i.i_product_name, '^.*[0-9]{2}.*$') THEN 'HasDigits'
        ELSE 'NoDigits'
      END AS product_name_flag
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i          ON ws.ws_item_sk      = i.i_item_sk
    JOIN web_site wsite  ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2002
      AND i.i_class LIKE '%scanners%'
      AND regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
      AND wsite.web_name LIKE '%Shop%'
      AND EXISTS (SELECT 1 FROM distinct_sites ds WHERE ds.web_name = wsite.web_name)
  ),
  inventory_agg AS (
    SELECT
      inv.inv_item_sk,
      inv.inv_date_sk,
      SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
      d.d_date
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    GROUP BY inv.inv_item_sk, inv.inv_date_sk, d.d_date
  ),
  orders_without_return AS (
    SELECT ws_order_number FROM sales_filtered
    EXCEPT
    SELECT wr_order_number FROM web_returns
  ),
  full_data AS (
    SELECT
      s.ws_order_number,
      s.d_date,
      s.product_qty_desc,
      s.product_name_flag,
      s.ws_ext_sales_price,
      s.ws_item_sk,
      s.ws_sold_date_sk,
      inv.total_qty_on_hand
    FROM sales_filtered s
    FULL OUTER JOIN inventory_agg inv
      ON s.ws_item_sk = inv.inv_item_sk
     AND s.ws_sold_date_sk = inv.inv_date_sk
  )
SELECT
  fd.ws_order_number,
  fd.d_date,
  fd.product_qty_desc,
  fd.product_name_flag,
  fd.ws_ext_sales_price,
  fd.total_qty_on_hand,
  (
    SELECT MAX(ws2.ws_ext_sales_price)
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = fd.ws_item_sk
      AND ws2.ws_sold_date_sk = fd.ws_sold_date_sk
  ) AS max_price_same_item_day,
  CASE
    WHEN fd.ws_order_number NOT IN (SELECT wr_order_number FROM web_returns) THEN 'NoReturn'
    ELSE 'Returned'
  END AS return_status
FROM full_data fd
WHERE fd.ws_order_number IN (SELECT ws_order_number FROM orders_without_return)
ORDER BY fd.ws_ext_sales_price DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
