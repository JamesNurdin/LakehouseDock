WITH distinct_manufacturers AS (
    SELECT DISTINCT i_manufact, i_manufact_id
    FROM item
    WHERE i_manufact_id IN (86, 625, 338)
),
item_expanded AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_units,
           i.i_manufact_id,
           i.i_manufact,
           word AS item_word
    FROM (
        SELECT i_item_sk,
               i_item_id,
               i_units,
               i_manufact_id,
               i_manufact,
               split(i_item_desc, ' ') AS words
        FROM item
    ) i
    CROSS JOIN UNNEST(words) AS t(word)
)
SELECT
    manufacturer,
    manufact_id,
    item_word,
    unit_category,
    total_return_amount,
    distinct_orders,
    loss_category
FROM (
    SELECT
        i.i_manufact AS manufacturer,
        i.i_manufact_id AS manufact_id,
        ie.item_word,
        CASE WHEN i.i_units = 'Box' THEN 'Boxed' ELSE 'Other' END AS unit_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        CASE WHEN SUM(cr.cr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN item_expanded ie ON i.i_item_sk = ie.i_item_sk
    JOIN distinct_manufacturers dm ON i.i_manufact_id = dm.i_manufact_id
    WHERE cr.cr_return_tax > 20
    GROUP BY i.i_manufact, i.i_manufact_id, ie.item_word, i.i_units

    UNION ALL

    SELECT
        i.i_manufact AS manufacturer,
        i.i_manufact_id AS manufact_id,
        ie.item_word,
        CASE WHEN i.i_units = 'Box' THEN 'Boxed' ELSE 'Other' END AS unit_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        CASE WHEN SUM(cr.cr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN item_expanded ie ON i.i_item_sk = ie.i_item_sk
    WHERE i.i_units = 'Box' AND cr.cr_return_tax BETWEEN 1 AND 10
    GROUP BY i.i_manufact, i.i_manufact_id, ie.item_word, i.i_units
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
