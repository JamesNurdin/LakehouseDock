WITH
  -- intersecting order numbers from catalog returns and web sales
  intersect_keys AS (
    SELECT cr_order_number AS order_number
    FROM catalog_returns
    INTERSECT
    SELECT ws_order_number AS order_number
    FROM web_sales
  ),

  -- catalog side: full outer join returns to sales, filter, compute case and row number
  catalog_part AS (
    SELECT
      COALESCE(cr.cr_order_number, cs.cs_order_number) AS order_number,
      CASE
        WHEN cr.cr_net_loss IS NULL THEN 'NoReturn'
        WHEN cr.cr_net_loss > 0      THEN 'Loss'
        ELSE 'Gain'
      END AS return_status,
      ROW_NUMBER() OVER (ORDER BY COALESCE(cr.cr_order_number, cs.cs_order_number)) AS rn
    FROM catalog_returns cr
    FULL OUTER JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    WHERE cr.cr_return_amount > (
            SELECT MAX(cs_ext_sales_price)
            FROM catalog_sales
            WHERE cs_quantity > 5
          )
      AND COALESCE(cr.cr_order_number, cs.cs_order_number) IN (SELECT order_number FROM intersect_keys)
  ),

  -- web side: full outer join returns to sales, filter, compute case and row number
  web_part AS (
    SELECT
      COALESCE(wr.wr_order_number, ws.ws_order_number) AS order_number,
      CASE
        WHEN wr.wr_net_loss IS NULL THEN 'NoReturn'
        WHEN wr.wr_net_loss > 0      THEN 'Loss'
        ELSE 'Gain'
      END AS return_status,
      ROW_NUMBER() OVER (ORDER BY COALESCE(wr.wr_order_number, ws.ws_order_number)) AS rn
    FROM web_returns wr
    FULL OUTER JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_amt > (
            SELECT MIN(ws_ext_sales_price)
            FROM web_sales
            WHERE ws_quantity > 3
          )
      AND COALESCE(wr.wr_order_number, ws.ws_order_number) IN (SELECT order_number FROM intersect_keys)
  )

SELECT *
FROM (
  SELECT * FROM catalog_part
  UNION ALL
  SELECT * FROM web_part
) AS combined
ORDER BY rn
