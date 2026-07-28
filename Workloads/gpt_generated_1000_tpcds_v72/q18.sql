/*
Goal: Compare total return amounts and quantities by item category across store and web channels for sales occurring during business hours (9‑17). The query unions store‑return and web‑return data, then uses GROUPING SETS to produce subtotals per category, per channel, and a grand total.
*/
WITH store_ret AS (
    SELECT
        i.i_category AS category,
        'store' AS channel,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category
),
web_ret AS (
    SELECT
        i.i_category AS category,
        'web' AS channel,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY i.i_category
)
SELECT
    category,
    channel,
    SUM(total_return_amount) AS total_return_amount,
    SUM(total_return_qty) AS total_return_qty
FROM (
    SELECT category, channel, total_return_amount, total_return_qty FROM store_ret
    UNION ALL
    SELECT category, channel, total_return_amount, total_return_qty FROM web_ret
) AS combined
GROUP BY GROUPING SETS (
    (category, channel),
    (category),
    (channel),
    ()
)
ORDER BY category NULLS LAST, channel NULLS LAST
LIMIT 100
