WITH brand_returns AS (
    SELECT
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM
        item i
        JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
    WHERE
        i.i_units IN ('Bunch', 'Bundle')
        AND i.i_size IS NOT NULL
        AND sr.sr_returned_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY
        i.i_brand,
        i.i_category
)
SELECT
    brand,
    category,
    total_net_loss,
    total_return_qty,
    total_return_amt,
    distinct_tickets,
    avg_return_amt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM brand_returns
WHERE total_net_loss > 0
ORDER BY net_loss_rank
LIMIT 10
