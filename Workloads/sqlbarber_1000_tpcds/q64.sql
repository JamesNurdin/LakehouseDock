SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_current_price,
    i.i_wholesale_cost,
    (i.i_current_price - i.i_wholesale_cost) AS price_margin,
    (i.i_current_price * i.i_wholesale_cost) AS price_product,
    CASE
        WHEN i.i_current_price > 6.54 THEN 'Expensive'
        ELSE 'Affordable'
    END AS price_category,
    CASE
        WHEN i.i_color IS NULL THEN 'UNKNOWN'
        ELSE i.i_color
    END AS item_color,
    CONCAT(i.i_product_name, ' - ', i.i_brand) AS full_name,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    (sr.sr_return_quantity * sr.sr_return_amt) AS total_return_amount,
    CASE
        WHEN sr.sr_return_quantity > 46 THEN 'Bulk'
        ELSE 'Single'
    END AS return_type,
    sr.sr_return_tax,
    sr.sr_return_amt_inc_tax,
    (sr.sr_return_amt_inc_tax - sr.sr_return_tax) AS net_return_without_tax
FROM
    item i
JOIN
    store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
WHERE
    i.i_category = 'Electronics                                       '
    AND sr.sr_returned_date_sk = 2451966
