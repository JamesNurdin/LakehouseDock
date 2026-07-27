WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        ca.ca_state,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        wp.wp_url,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returned_date_sk
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
),
agg AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        ca_state,
        hd_buy_potential,
        ib_upper_bound,
        wp_url,
        wr_return_amt,
        SUM(wr_return_amt) OVER (PARTITION BY c_customer_sk) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY hd_buy_potential ORDER BY wr_return_amt DESC) AS rn_by_potential
    FROM base
    WHERE hd_buy_potential = '>10000'
      AND ib_upper_bound >= 100000
      AND wr_return_amt > 1000
)
SELECT
    c_customer_id,
    ca_state,
    hd_buy_potential,
    ib_upper_bound,
    wp_url,
    wr_return_amt,
    total_return_amt,
    RANK() OVER (ORDER BY total_return_amt DESC) AS revenue_rank,
    rn_by_potential
FROM agg
ORDER BY revenue_rank
LIMIT 100
