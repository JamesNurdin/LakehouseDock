WITH
  sold_items AS (
    SELECT DISTINCT ss_item_sk
    FROM store_sales
  ),
  returned_items AS (
    SELECT DISTINCT cr_item_sk
    FROM catalog_returns
  ),
  sold_not_returned AS (
    SELECT ss_item_sk
    FROM sold_items
    EXCEPT
    SELECT cr_item_sk
    FROM returned_items
  ),
  item_arrays AS (
    SELECT
      i_item_sk,
      i_brand,
      i_category,
      i_product_name,
      array[i_brand_id, i_category_id] AS ids_arr
    FROM item
  ),
  unnested_ids AS (
    SELECT
      ia.i_item_sk,
      ia.i_brand,
      ia.i_category,
      ia.i_product_name,
      id AS id_value
    FROM item_arrays ia
    CROSS JOIN UNNEST(ia.ids_arr) AS t(id)
  ),
  sales_data AS (
    SELECT
      ss.ss_item_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '(?i)deluxe')
    GROUP BY ss.ss_item_sk
  ),
  returns_data AS (
    SELECT
      cr.cr_item_sk,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(*) AS returns_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_product_name, '(?i)deluxe')
    GROUP BY cr.cr_item_sk
  ),
  full_item_inventory AS (
    SELECT
      i.i_item_sk,
      i.i_brand,
      i.i_category,
      i.i_product_name,
      inv.inv_quantity_on_hand,
      i.i_brand_id,
      i.i_category_id
    FROM item i
    FULL OUTER JOIN inventory inv
      ON i.i_item_sk = inv.inv_item_sk
  )
SELECT
  concat(fi.i_brand, '-', fi.i_category) AS brand_category,
  fi.i_product_name,
  fi.inv_quantity_on_hand,
  sd.total_sales,
  rd.total_returns,
  sd.total_profit,
  COUNT(unn.id_value) AS id_count
FROM
  full_item_inventory fi
  LEFT JOIN sales_data sd ON fi.i_item_sk = sd.ss_item_sk
  LEFT JOIN returns_data rd ON fi.i_item_sk = rd.cr_item_sk
  LEFT JOIN unnested_ids unn ON fi.i_item_sk = unn.i_item_sk
WHERE
  fi.i_product_name IS NOT NULL
  AND regexp_like(fi.i_product_name, '(?i)deluxe')
  AND (
        (fi.i_brand IS NOT NULL AND fi.i_brand LIKE '%Brand%')
        OR fi.i_category LIKE '%Category%'
      )
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN call_center cc ON cr2.cr_call_center_sk = cc.cc_call_center_sk
        WHERE cr2.cr_item_sk = fi.i_item_sk
          AND cc.cc_name LIKE '%Center%'
      )
  AND fi.i_item_sk IN (SELECT ss_item_sk FROM sold_not_returned)
GROUP BY
  concat(fi.i_brand, '-', fi.i_category),
  fi.i_product_name,
  fi.inv_quantity_on_hand,
  sd.total_sales,
  rd.total_returns,
  sd.total_profit
HAVING
  SUM(COALESCE(sd.total_sales, 0)) > 10000
ORDER BY
  sd.total_sales DESC
LIMIT 100
