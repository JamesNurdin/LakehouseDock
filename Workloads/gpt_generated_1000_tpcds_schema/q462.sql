WITH
  common_items AS (
    SELECT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    WHERE ws.ws_ship_cdemo_sk = 215362
    INTERSECT
    SELECT i.i_item_sk
    FROM item i
    WHERE i.i_formulation LIKE '%blue%'
  ),
  filtered_sales AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      ws.ws_quantity,
      ws.ws_ext_sales_price,
      ws.ws_ext_discount_amt,
      i.i_brand,
      i.i_category,
      i.i_color,
      i.i_formulation
    FROM web_sales ws
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_ship_customer_sk IN (11996091, 11185919)
      AND i.i_brand_id = 3002001
      AND ws.ws_item_sk IN (SELECT item_sk FROM common_items)
  ),
  agg_union AS (
    SELECT
      f.i_brand AS brand,
      f.i_category AS category,
      f.i_color AS color,
      SUM(f.ws_ext_sales_price) AS total_sales,
      SUM(f.ws_quantity) AS total_qty
    FROM filtered_sales f
    GROUP BY f.i_brand, f.i_category, f.i_color

    UNION

    SELECT
      f.i_brand AS brand,
      f.i_category AS category,
      NULL AS color,
      SUM(f.ws_ext_sales_price) AS total_sales,
      SUM(f.ws_quantity) AS total_qty
    FROM filtered_sales f
    WHERE f.i_formulation LIKE '%sky%'
    GROUP BY f.i_brand, f.i_category
  )
SELECT
  brand,
  category,
  color,
  SUM(total_sales) AS total_sales,
  SUM(total_qty) AS total_qty,
  AVG(
    (SELECT AVG(fs2.ws_ext_discount_amt)
     FROM filtered_sales fs2
     WHERE fs2.i_brand = agg.brand)
  ) AS avg_discount
FROM agg_union agg
GROUP BY CUBE (brand, category, color)
ORDER BY brand ASC NULLS LAST, total_sales DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
