WITH
  promoted_items AS (
    SELECT DISTINCT p_item_sk
    FROM promotion
  ),
  sold_items AS (
    SELECT DISTINCT ws_item_sk
    FROM web_sales
  ),
  non_promoted_items AS (
    SELECT ws_item_sk
    FROM sold_items
    EXCEPT
    SELECT p_item_sk
    FROM promoted_items
  ),
  agg_sales AS (
    SELECT
      d.d_year                                 AS d_year,
      i.i_item_id                              AS i_item_id,
      i.i_product_name                         AS i_product_name,
      SUM(ws.ws_net_paid)                      AS total_net_paid,
      SUM(ws.ws_quantity)                      AS total_quantity,
      CASE WHEN SUM(ws.ws_quantity) > 1000 THEN 'High' ELSE 'Low' END AS sales_volume_category
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)gold')
      AND ca.ca_city LIKE 'San%'
      AND ws.ws_item_sk IN (SELECT ws_item_sk FROM non_promoted_items)
      AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = ws.ws_item_sk
          AND cr.cr_returned_date_sk = ws.ws_sold_date_sk
      )
    GROUP BY d.d_year, i.i_item_id, i.i_product_name
  )
SELECT
  d_year,
  i_item_id,
  i_product_name,
  total_net_paid,
  total_quantity,
  sales_volume_category,
  lag(total_net_paid) OVER (PARTITION BY i_item_id ORDER BY d_year)               AS lag_total_net_paid,
  sum(total_net_paid) OVER (PARTITION BY i_item_id ORDER BY d_year
                             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_net_paid
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 100
