WITH filtered_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_brand = 'Brand#23'
)
SELECT
    d_all.d_year,
    s.s_store_name,
    ws.web_name,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    SUM(sr.sr_return_amt) AS store_return_total,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    SUM(iinv.inv_quantity_on_hand) AS total_quantity_on_hand
FROM
    inventory iinv
    RIGHT OUTER JOIN date_dim d_all
        ON iinv.inv_date_sk = d_all.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_all.d_date_sk
        AND sr.sr_item_sk = iinv.inv_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_all.d_date_sk
        AND cr.cr_item_sk = iinv.inv_item_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_all.d_date_sk
        AND wr.wr_item_sk = iinv.inv_item_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d_all.d_date_sk
    LEFT JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN item i
        ON iinv.inv_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE
    sr.sr_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand = 'Brand#23')
    AND d_all.d_year = 2001
GROUP BY
    d_all.d_year,
    s.s_store_name,
    ws.web_name
ORDER BY
    d_all.d_year,
    s.s_store_name
LIMIT 100
