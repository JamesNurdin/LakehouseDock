WITH base_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        d.d_year,
        i.i_item_sk,
        i.i_class_id,
        i.i_current_price,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        ca.ca_state,
        inv.inv_quantity_on_hand,
        ss.ss_net_profit,
        COALESCE(sr.sr_return_quantity, 0) AS return_qty,
        COALESCE(sr.sr_return_amt, 0) AS return_amt
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
        AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND d.d_date_sk = sr.sr_returned_date_sk
    WHERE
        d.d_year = 2001
        AND i.i_current_price > 5.00
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_upper_bound <= 80000
        AND ca.ca_state = 'CA'
        AND inv.inv_quantity_on_hand > 0
),
sales_agg AS (
    SELECT
        i_class_id AS class_id,
        ib_income_band_sk AS income_band_sk,
        SUM(ss_net_profit) AS total_profit,
        SUM(return_qty) AS total_return_qty,
        SUM(return_amt) AS total_return_amt,
        COUNT(DISTINCT ss_ticket_number) AS num_transactions
    FROM base_data
    GROUP BY i_class_id, ib_income_band_sk
)
SELECT
    class_id,
    income_band_sk,
    total_profit,
    total_return_qty,
    total_return_amt,
    num_transactions,
    total_profit / NULLIF(num_transactions, 0) AS avg_profit_per_tx,
    total_return_qty * 1.0 / NULLIF(num_transactions, 0) AS avg_return_qty_per_tx
FROM sales_agg
WHERE total_profit > 1000
ORDER BY total_profit DESC
LIMIT 100
