WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1980
      AND ca.ca_state = 'CA'
      AND ib.ib_upper_bound <= 80000
      AND i.i_current_price > 20
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_sold_date_sk = sr.sr_returned_date_sk
            AND ws.ws_net_profit > 0
      )
)
SELECT
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.c_birth_year,
    b.ca_state,
    b.i_product_name,
    b.i_current_price,
    b.sr_returned_date_sk,
    b.sr_return_quantity,
    b.sr_return_amt,
    SUM(b.sr_return_amt) OVER (PARTITION BY b.ca_state ORDER BY b.sr_return_amt DESC) AS cum_return_amt_state,
    ROW_NUMBER() OVER (PARTITION BY b.ca_state ORDER BY b.sr_return_amt DESC) AS rn_state_by_return
FROM base b
ORDER BY b.ca_state, rn_state_by_return
LIMIT 100
