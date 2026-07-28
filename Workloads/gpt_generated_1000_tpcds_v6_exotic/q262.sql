WITH filtered AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_ext_wholesale_cost,
        cr.cr_return_amount,
        i.i_item_id,
        i.i_manufact,
        ca_s.ca_state,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca_s
        ON ss.ss_addr_sk = ca_s.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_r
        ON cr.cr_refunded_addr_sk = ca_r.ca_address_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_manufact = 'barprically'
      AND ss.ss_ext_wholesale_cost > 5000
      AND cr.cr_store_credit BETWEEN 50 AND 200
      AND inv.inv_quantity_on_hand > 100
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_item_sk = i.i_item_sk
            AND cr2.cr_return_quantity > 0
      )
)
SELECT
    i_item_id,
    i_manufact,
    ca_state,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ss_ticket_number) AS sales_transactions,
    AVG(inv_quantity_on_hand) AS avg_quantity_on_hand
FROM filtered
GROUP BY i_item_id, i_manufact, ca_state
ORDER BY total_net_profit DESC
LIMIT 100
