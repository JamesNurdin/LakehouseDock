WITH distinct_returns AS (
    SELECT DISTINCT
        sr.sr_ticket_number,
        sr.sr_item_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        hd.hd_dep_count,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price BETWEEN 10 AND 200
      AND ca.ca_state = 'CA'
      AND hd.hd_dep_count IN (2, 4, 5)
      AND ib.ib_upper_bound > 50000
)
SELECT
    dr.i_item_id,
    dr.i_item_desc,
    SUM(dr.sr_return_amt) AS total_store_return_amt,
    SUM(dr.wr_return_amt) AS total_web_return_amt,
    SUM(dr.sr_return_amt + dr.wr_return_amt) AS total_combined_return_amt,
    AVG(dr.ib_lower_bound) AS avg_income_lower_bound,
    COUNT(DISTINCT dr.sr_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT dr.wr_order_number) AS distinct_web_orders
FROM distinct_returns dr
GROUP BY dr.i_item_id, dr.i_item_desc
HAVING SUM(dr.sr_return_amt + dr.wr_return_amt) > 1000
   AND AVG(dr.ib_lower_bound) BETWEEN 60000 AND 150000
ORDER BY total_combined_return_amt DESC
LIMIT 100
