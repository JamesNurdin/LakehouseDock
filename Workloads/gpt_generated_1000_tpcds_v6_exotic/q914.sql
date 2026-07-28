WITH filtered_returns AS (
    SELECT
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_item_sk,
        wr_refunded_customer_sk,
        wr_refunded_cdemo_sk,
        wr_refunded_hdemo_sk,
        wr_refunded_addr_sk,
        wr_returning_customer_sk,
        wr_returning_cdemo_sk,
        wr_returning_hdemo_sk,
        wr_returning_addr_sk,
        wr_web_page_sk,
        wr_reason_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        wr_return_amt_inc_tax,
        wr_fee,
        wr_return_ship_cost,
        wr_refunded_cash,
        wr_reversed_charge,
        wr_account_credit,
        wr_net_loss
    FROM web_returns
    WHERE wr_return_quantity > 1
      AND wr_return_amt > 50
      AND wr_account_credit < 400
      AND wr_returned_date_sk BETWEEN 2450000 AND 2450100
      AND wr_reason_sk IS NOT NULL
      AND wr_returning_customer_sk IS NOT NULL
),
joined_data AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        fr.wr_order_number,
        fr.wr_net_loss,
        fr.wr_return_amt
    FROM filtered_returns fr
    JOIN customer c
        ON fr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON fr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON fr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ca.ca_state = 'CA'
      AND ca.ca_city = 'Seattle'
      AND c.c_birth_country = 'KOREA'
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_buy_potential = '5001-10000'
      AND ib.ib_upper_bound BETWEEN 50000 AND 150000
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_vehicle_count,
    COUNT(DISTINCT wr_order_number) AS distinct_orders_returned,
    SUM(wr_net_loss) AS total_net_loss,
    AVG(wr_return_amt) AS avg_return_amount,
    MIN(wr_net_loss) AS min_net_loss,
    MAX(wr_net_loss) AS max_net_loss
FROM joined_data
GROUP BY ib_lower_bound, ib_upper_bound, hd_vehicle_count
ORDER BY total_net_loss DESC
LIMIT 100
