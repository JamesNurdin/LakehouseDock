SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_color,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM
    store_returns sr
JOIN
    item i
    ON sr.sr_item_sk = i.i_item_sk
WHERE
    i.i_color IN ('pale', 'royal')
    AND i.i_category_id = 5
    AND i.i_rec_start_date <= DATE '2001-12-31'
    AND sr.sr_return_quantity > 10
    AND sr.sr_return_time_sk BETWEEN 30000 AND 35000
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_color
