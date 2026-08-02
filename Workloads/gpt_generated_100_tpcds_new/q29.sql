SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    SUM(p.p_cost) AS total_promo_cost
FROM
    tpcds.item AS i
JOIN
    tpcds.promotion AS p
    ON p.p_item_sk = i.i_item_sk
WHERE
    i.i_category_id = 5
    AND p.p_channel_tv = 'N'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_category
ORDER BY
    total_promo_cost DESC
LIMIT 10
