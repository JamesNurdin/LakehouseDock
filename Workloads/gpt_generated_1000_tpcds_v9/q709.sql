WITH store_ret AS (
    SELECT
        td.t_hour,
        'STORE' AS source_type,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_net_loss AS net_loss,
        CASE
            WHEN sr.sr_net_loss >= 1000 THEN 'High'
            WHEN sr.sr_net_loss >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category
    FROM store_returns sr
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE sr.sr_net_loss > 0
      AND td.t_sub_shift = 'morning'
      AND ss.ss_sales_price > 0
),
catalog_ret AS (
    SELECT
        td.t_hour,
        'CATALOG' AS source_type,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_net_loss AS net_loss,
        CASE
            WHEN cr.cr_net_loss >= 1000 THEN 'High'
            WHEN cr.cr_net_loss >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_net_loss > 0
      AND td.t_minute IN (5, 7, 15)
)
SELECT
    t_hour,
    source_type,
    loss_category,
    SUM(return_quantity) AS total_return_qty,
    SUM(net_loss) AS total_net_loss
FROM (
    SELECT t_hour, source_type, return_quantity, net_loss, loss_category FROM store_ret
    UNION ALL
    SELECT t_hour, source_type, return_quantity, net_loss, loss_category FROM catalog_ret
) AS unified
GROUP BY GROUPING SETS (
    (t_hour, source_type, loss_category),
    (t_hour, source_type),
    (source_type),
    ()
)
ORDER BY
    t_hour NULLS LAST,
    source_type,
    loss_category
LIMIT 100
