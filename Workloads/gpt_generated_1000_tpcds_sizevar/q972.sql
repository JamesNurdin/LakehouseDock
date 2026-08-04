WITH
  sold_items AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    UNION
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),
  returned_items AS (
    SELECT DISTINCT cr.cr_item_sk AS item_sk
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    UNION
    SELECT DISTINCT wr.wr_item_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),
  sold_not_returned AS (
    SELECT item_sk FROM sold_items
    EXCEPT
    SELECT item_sk FROM returned_items
  ),
  inventory_2020 AS (
    SELECT inv.inv_item_sk AS item_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),
  promo_items AS (
    SELECT DISTINCT p.p_item_sk AS item_sk
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk <= d.d_date_sk
                      AND p.p_end_date_sk >= d.d_date_sk
    WHERE d.d_year = 2020
  ),
  join_result AS (
    SELECT DISTINCT COALESCE(snr.item_sk, inv.item_sk) AS item_sk,
                    inv.inv_quantity_on_hand
    FROM sold_not_returned snr
    FULL OUTER JOIN inventory_2020 inv ON snr.item_sk = inv.item_sk
  ),
  final_items AS (
    SELECT item_sk FROM join_result
    INTERSECT
    SELECT item_sk FROM promo_items
  )
SELECT
  i.i_item_id,
  i.i_product_name,
  COALESCE(jr.inv_quantity_on_hand, 0) AS quantity_on_hand,
  'Sold_NoReturn_Promo' AS source
FROM final_items fi
JOIN item i ON fi.item_sk = i.i_item_sk
LEFT JOIN (
  SELECT item_sk, inv_quantity_on_hand
  FROM join_result
) jr ON fi.item_sk = jr.item_sk
ORDER BY i.i_item_id
LIMIT 100
