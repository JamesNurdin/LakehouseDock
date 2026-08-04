WITH
  returns_excluding_sales AS (
    SELECT cr_order_number
    FROM catalog_returns
    EXCEPT
    SELECT ws_order_number
    FROM web_sales
  ),
  base_returns AS (
    SELECT
      cr.cr_order_number,
      cr.cr_return_amount,
      i.i_brand,
      r.r_reason_desc,
      CONCAT(i.i_brand, ':', r.r_reason_desc) AS brand_reason
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, 'color')
      AND i.i_item_desc LIKE '%large%'
      AND cr.cr_order_number IN (SELECT cr_order_number FROM returns_excluding_sales)
  ),
  base_sales AS (
    SELECT
      ws.ws_order_number,
      ws.ws_ext_sales_price,
      i.i_brand
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_item_desc LIKE '%large%'
  )
SELECT
  COALESCE(br.r_reason_desc, 'ALL REASONS') AS reason_desc,
  COALESCE(br.i_brand, 'ALL BRANDS') AS brand,
  SUM(br.cr_return_amount) AS total_return_amount,
  SUM(bs.ws_ext_sales_price) AS total_sales_amount,
  COUNT(DISTINCT br.cr_order_number) AS return_orders,
  COUNT(DISTINCT bs.ws_order_number) AS sales_orders,
  lr.brand_reason_len
FROM base_returns br
LEFT JOIN base_sales bs
  ON br.cr_order_number = bs.ws_order_number
  AND br.i_brand = bs.i_brand
CROSS JOIN LATERAL (
  SELECT length(br.brand_reason) AS brand_reason_len
) lr
GROUP BY ROLLUP (br.r_reason_desc, br.i_brand, lr.brand_reason_len)
ORDER BY total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
