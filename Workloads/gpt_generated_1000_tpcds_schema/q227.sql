WITH base AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_time_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_net_loss,
        td.t_hour,
        ca.ca_state        AS ship_address_state,
        ca3.ca_state       AS current_address_state,
        c.c_current_hdemo_sk,
        c.c_current_addr_sk,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        hd2.hd_income_band_sk AS hd2_income_band_sk,
        ib2.ib_upper_bound    AS ib2_upper_bound
    FROM store_returns sr
    INNER JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    INNER JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    INNER JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN household_demographics hd2
        ON c.c_current_hdemo_sk = hd2.hd_demo_sk
    INNER JOIN income_band ib2
        ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    INNER JOIN customer_address ca3
        ON c.c_current_addr_sk = ca3.ca_address_sk
    FULL OUTER JOIN customer_address ca2
        ON sr.sr_addr_sk = ca2.ca_address_sk
),
keys1 AS (
    SELECT DISTINCT sr_customer_sk
    FROM base
    WHERE sr_return_amt > 10
),
keys2 AS (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    INNER JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
intersect_keys AS (
    SELECT sr_customer_sk FROM keys1
    INTERSECT
    SELECT c_customer_sk FROM keys2
),
aggregated AS (
    SELECT
        b.sr_customer_sk,
        b.sr_return_amt,
        b.sr_fee,
        b.t_hour,
        b.ship_address_state,
        b.current_address_state,
        COUNT(DISTINCT b.sr_item_sk)          AS distinct_items,
        COUNT(DISTINCT b.sr_return_quantity) AS distinct_quantities,
        ROW_NUMBER() OVER (PARTITION BY b.sr_customer_sk ORDER BY b.sr_return_amt DESC) AS rn
    FROM base b
    INNER JOIN intersect_keys ik
        ON b.sr_customer_sk = ik.sr_customer_sk
    GROUP BY
        b.sr_customer_sk,
        b.sr_return_amt,
        b.sr_fee,
        b.t_hour,
        b.ship_address_state,
        b.current_address_state
)
SELECT *
FROM aggregated
ORDER BY rn DESC, sr_customer_sk
