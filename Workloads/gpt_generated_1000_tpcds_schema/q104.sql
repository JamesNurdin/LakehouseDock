WITH catalog_agg AS (
    SELECT
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_tax,
        (
            SELECT SUM(sr.sr_return_quantity)
            FROM store_returns sr
            WHERE sr.sr_item_sk = cs.cs_item_sk
        ) AS total_return_qty
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
      AND cs.cs_ext_tax > (
          SELECT AVG(cs2.cs_ext_tax)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk BETWEEN 2450800 AND 2450820
      )
)

SELECT
    'catalog' AS source,
    ca.cs_item_sk AS item_sk,
    i.i_product_name,
    ca.cs_quantity,
    ca.cs_ext_sales_price,
    ca.total_return_qty
FROM catalog_agg ca
JOIN item i ON ca.cs_item_sk = i.i_item_sk

UNION ALL

SELECT
    'web' AS source,
    ws.ws_item_sk AS item_sk,
    i2.i_product_name,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    (
        SELECT SUM(sr2.sr_return_quantity)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = ws.ws_item_sk
    ) AS total_return_qty
FROM web_sales ws
JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
  AND ws.ws_ext_tax > (
      SELECT AVG(ws2.ws_ext_tax)
      FROM web_sales ws2
      WHERE ws2.ws_sold_date_sk BETWEEN 2450800 AND 2450820
  )

LIMIT 100
