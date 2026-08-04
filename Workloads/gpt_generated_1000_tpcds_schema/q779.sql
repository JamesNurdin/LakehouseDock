WITH sampled_sales AS (
    SELECT ss_ticket_number,
           ss_sold_date_sk,
           ss_net_paid,
           ss_store_sk
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
    WHERE ss_sold_date_sk BETWEEN 2451545 AND 2451910
),

sales_tickets AS (
    SELECT DISTINCT ss_ticket_number
    FROM sampled_sales
    WHERE ss_net_paid > 0
),

return_tickets AS (
    SELECT DISTINCT sr_ticket_number
    FROM store_returns
    WHERE sr_return_amt > 0
),

intersect_tickets AS (
    SELECT ss_ticket_number AS ticket_number
    FROM sales_tickets
    INTERSECT
    SELECT sr_ticket_number
    FROM return_tickets
),

except_tickets AS (
    SELECT ss_ticket_number AS ticket_number
    FROM sales_tickets
    EXCEPT
    SELECT sr_ticket_number
    FROM return_tickets
),

final_set AS (
    SELECT it.ticket_number,
           'INTERSECT' AS source_type,
           CASE WHEN (it.ticket_number % 2) = 0 THEN 'EVEN' ELSE 'ODD' END AS ticket_parity,
           (SELECT SUM(r.sr_return_amt)
            FROM store_returns r
            WHERE r.sr_ticket_number = it.ticket_number) AS total_return_amount
    FROM intersect_tickets it
    UNION ALL
    SELECT et.ticket_number,
           'EXCEPT' AS source_type,
           CASE WHEN (et.ticket_number % 2) = 0 THEN 'EVEN' ELSE 'ODD' END AS ticket_parity,
           (SELECT SUM(r.sr_return_amt)
            FROM store_returns r
            WHERE r.sr_ticket_number = et.ticket_number) AS total_return_amount
    FROM except_tickets et
)
SELECT ticket_number,
       source_type,
       ticket_parity,
       total_return_amount
FROM final_set
ORDER BY ticket_number
LIMIT 100
