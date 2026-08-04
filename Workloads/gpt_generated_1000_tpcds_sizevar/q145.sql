WITH
  missing_order_numbers AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
  ),
  returns_agg AS (
    SELECT
      i.i_category,
      d.d_year,
      CONCAT(i.i_brand, ' ', i.i_color) AS brand_color,
      cr.cr_item_sk,
      COUNT(*) AS return_cnt,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(ca.ca_city, 'County')
      AND i.i_item_desc LIKE '%steel%'
    GROUP BY i.i_category, d.d_year, CONCAT(i.i_brand, ' ', i.i_color), cr.cr_item_sk
  )
SELECT
  r.i_category,
  r.d_year,
  r.brand_color,
  r.return_cnt,
  r.total_return_amount,
  r.total_net_loss,
  (
    SELECT SUM(ws.ws_net_paid)
    FROM web_sales ws
    WHERE ws.ws_item_sk = r.cr_item_sk
  ) AS total_web_sales,
  (
    SELECT ARRAY_AGG(m.cr_order_number)
    FROM missing_order_numbers m
    WHERE m.cr_order_number = r.cr_item_sk
  ) AS missing_order_numbers_for_item
FROM returns_agg r
ORDER BY r.total_return_amount DESC
LIMIT 100
