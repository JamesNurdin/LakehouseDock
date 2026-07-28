/*
  Goal: Analyze sales performance by store and item category, incorporating inventory levels and both store and web returns. The query joins all seven selected TPC‑DS tables using the permitted join keys, applies a suite of realistic filter predicates, uses LEFT OUTER JOINs to retain sales rows even when return or inventory information is missing, and aggregates key monetary and volume measures.
*/
WITH sales_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_addr_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        ca.ca_city,
        ca.ca_state,
        s.s_store_name,
        s.s_gmt_offset
    FROM store_sales ss
    JOIN item i               ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca  ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s              ON ss.ss_store_sk = s.s_store_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'               -- filter 1
      AND ca.ca_state = 'CA'                                   -- filter 2
      AND s.s_gmt_offset BETWEEN -5.00 AND 0.00                -- filter 3
      AND ss.ss_quantity > 1                                   -- filter 4
      AND ss.ss_net_paid > 10.00                               -- filter 5
      AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910      -- filter 6
)
SELECT
    sd.s_store_name,
    sd.i_category,
    COUNT(DISTINCT sd.ss_ticket_number)                     AS num_sales_transactions,
    SUM(sd.ss_net_paid)                                      AS total_sales_amount,
    AVG(sd.i_current_price)                                  AS avg_item_price,
    SUM(COALESCE(sr.sr_net_loss, 0))                         AS total_store_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0))                         AS total_web_return_loss,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0))               AS total_inventory_on_hand
FROM sales_data sd
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sd.ss_ticket_number
   AND sr.sr_item_sk = sd.ss_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = sd.ss_item_sk
   AND wr.wr_refunded_addr_sk = sd.ss_addr_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = sd.ss_item_sk
WHERE (sr.sr_return_amt > 5.00 OR sr.sr_return_amt IS NULL)      -- filter 7
  AND (wr.wr_return_amt > 3.00 OR wr.wr_return_amt IS NULL)      -- filter 8
  AND (inv.inv_quantity_on_hand > 50 OR inv.inv_quantity_on_hand IS NULL) -- filter 9
GROUP BY
    sd.s_store_name,
    sd.i_category
ORDER BY total_sales_amount DESC
LIMIT 100
