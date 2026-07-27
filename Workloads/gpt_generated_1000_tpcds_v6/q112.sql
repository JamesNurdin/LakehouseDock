WITH filtered AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_order_number,
        i.i_manufact,
        i.i_item_desc,
        i.i_color,
        i.i_product_name,
        c.c_salutation,
        t.t_am_pm,
        i.i_color AS i_color_original
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '\\bre\\w+')
      AND c.c_salutation LIKE 'Mr.%'
      AND t.t_am_pm = 'PM'
      AND concat('ORD', CAST(cr.cr_order_number AS varchar)) LIKE 'ORD5%'
      AND substring(i.i_product_name, 1, 3) = 'Pro'
)
SELECT
    i_manufact,
    regexp_extract(i_color_original, '([a-z]+)', 1) AS color,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM filtered
GROUP BY
    i_manufact,
    regexp_extract(i_color_original, '([a-z]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
