WITH inv_cte AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2451067
      AND inv_quantity_on_hand > 100
)
SELECT
    i.i_item_id   AS item_id,
    i.i_item_desc AS item_desc,
    cr.cr_return_amount AS return_amount,
    'catalog'    AS return_source,
    (SELECT avg(i2.i_current_price) FROM item i2) AS avg_price
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE cr.cr_fee > 10
  AND EXISTS (SELECT 1 FROM inv_cte ic WHERE ic.inv_item_sk = cr.cr_item_sk)

UNION ALL

SELECT
    i.i_item_id   AS item_id,
    i.i_item_desc AS item_desc,
    wr.wr_return_amt AS return_amount,
    'web'        AS return_source,
    (SELECT avg(i2.i_current_price) FROM item i2) AS avg_price
FROM web_returns wr
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE wr.wr_return_ship_cost > 500
  AND EXISTS (SELECT 1 FROM inv_cte ic WHERE ic.inv_item_sk = wr.wr_item_sk)

ORDER BY return_amount DESC
LIMIT 100
