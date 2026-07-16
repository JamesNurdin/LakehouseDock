WITH agg AS (
    SELECT
        ca.ca_state,
        i.i_brand,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state IN ('AZ', 'NM', 'PA', 'CO', 'MO')
      AND sr.sr_return_quantity > 0
      AND sr.sr_returned_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ca.ca_state, i.i_brand
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    ca_state,
    i_brand,
    total_return_amount,
    avg_net_loss,
    distinct_tickets,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_return_amount DESC) AS brand_rank
FROM agg
ORDER BY ca_state, total_return_amount DESC
LIMIT 100
