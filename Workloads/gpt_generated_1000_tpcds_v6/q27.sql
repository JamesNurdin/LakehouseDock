WITH agg_sales AS (
    SELECT
        ss_item_sk,
        ss_addr_sk,
        ss_store_sk,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_net_profit) AS avg_net_profit
    FROM store_sales
    WHERE ss_ext_list_price > 1000.00
    GROUP BY ss_item_sk, ss_addr_sk, ss_store_sk
)
SELECT
    ca.ca_state,
    ca.ca_city,
    agg.ss_item_sk,
    SUM(sr.sr_net_loss) AS store_return_loss,
    SUM(cr.cr_net_loss) AS catalog_return_loss,
    SUM(wr.wr_net_loss) AS web_return_loss,
    SUM(sr.sr_net_loss + cr.cr_net_loss + wr.wr_net_loss) AS total_return_loss,
    agg.total_net_paid,
    agg.avg_net_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets
FROM agg_sales agg
JOIN customer_address ca
    ON agg.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_item_sk = agg.ss_item_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN web_returns wr
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_state = 'CA'
    AND ca.ca_gmt_offset = -5.00
    AND cr.cr_fee > 20.00
    AND sr.sr_return_quantity > 1
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = agg.ss_item_sk
          AND wr2.wr_net_loss > 0
          AND wr2.wr_refunded_addr_sk = ca.ca_address_sk
    )
GROUP BY
    ca.ca_state,
    ca.ca_city,
    agg.ss_item_sk,
    agg.total_net_paid,
    agg.avg_net_profit
ORDER BY total_return_loss DESC
LIMIT 100
