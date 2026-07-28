/* goal: Compare total net loss by item category for store returns versus catalog returns over a recent period */
WITH store_ret AS (
    SELECT
        i.i_category AS category,
        'store' AS source,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store_sales ss
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450935
    GROUP BY i.i_category
),
catalog_ret AS (
    SELECT
        i.i_category AS category,
        'catalog' AS source,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2450935
    GROUP BY i.i_category
)
SELECT *
FROM store_ret
UNION ALL
SELECT *
FROM catalog_ret
ORDER BY total_net_loss DESC
LIMIT 100
