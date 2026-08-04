WITH inv_store AS (
    SELECT
        i.inv_item_sk,
        i.inv_date_sk,
        i.inv_quantity_on_hand,
        s.s_store_id,
        d.d_year,
        d.d_date_sk,
        LAG(i.inv_quantity_on_hand) OVER (PARTITION BY i.inv_item_sk ORDER BY d.d_date_sk) AS prev_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    FULL OUTER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
)
SELECT
    'Inventory'        AS source,
    inv.inv_item_sk    AS item_sk,
    inv.s_store_id     AS store_id,
    inv.d_year         AS year,
    inv.inv_quantity_on_hand AS quantity_on_hand,
    inv.prev_qty       AS previous_quantity,
    price_val          AS price_value
FROM inv_store inv
JOIN item it ON inv.inv_item_sk = it.i_item_sk
CROSS JOIN UNNEST(ARRAY[it.i_current_price, it.i_wholesale_cost]) AS t(price_val)
WHERE inv.inv_item_sk IN (
        SELECT i_item_sk FROM item WHERE i_brand = 'BrandX'
    )
  AND inv.d_year = 2002
UNION
SELECT
    'Returned'        AS source,
    wr.wr_item_sk     AS item_sk,
    CAST(NULL AS varchar) AS store_id,
    dd.d_year         AS year,
    CAST(NULL AS integer) AS quantity_on_hand,
    CAST(NULL AS integer) AS previous_quantity,
    price_val         AS price_value
FROM web_returns wr
JOIN date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
JOIN item it2 ON wr.wr_item_sk = it2.i_item_sk
CROSS JOIN UNNEST(ARRAY[it2.i_current_price, it2.i_wholesale_cost]) AS t(price_val)
WHERE wr.wr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2002
    )
  AND it2.i_category = 'Sports'
LIMIT 100
