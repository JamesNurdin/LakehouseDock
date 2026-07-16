WITH filtered_returns AS (
    SELECT
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_returned_date_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returning_addr_sk,
        wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 20200101 AND 20201231
      AND wr.wr_return_quantity > 0
),
aggregated AS (
    SELECT
        ca_refunded.ca_state AS refunded_state,
        ib.ib_income_band_sk AS income_band_id,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(DISTINCT fr.wr_order_number) AS distinct_orders,
        SUM(fr.wr_net_loss) AS total_net_loss,
        AVG(fr.wr_return_amt_inc_tax) AS avg_return_amount_inc_tax,
        SUM(fr.wr_return_quantity) AS total_quantity
    FROM filtered_returns fr
    JOIN household_demographics hd_refunded
        ON fr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON fr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_refunded
        ON fr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON fr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN income_band ib
        ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca_refunded.ca_location_type = 'condo'
      AND ca_returning.ca_state = 'AZ'
    GROUP BY
        ca_refunded.ca_state,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    HAVING SUM(fr.wr_net_loss) > 1000
)
SELECT
    refunded_state,
    income_band_id,
    ib_lower_bound,
    ib_upper_bound,
    distinct_orders,
    total_net_loss,
    avg_return_amount_inc_tax,
    total_quantity,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY total_net_loss DESC
LIMIT 50
