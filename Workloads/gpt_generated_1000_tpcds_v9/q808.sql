WITH returning AS (
    SELECT
        c.c_customer_sk AS c_customer_sk,
        c.c_first_name AS c_first_name,
        c.c_last_name AS c_last_name,
        hd.hd_buy_potential AS hd_buy_potential,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        'returning' AS role
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
      AND wp.wp_type = 'product'
      AND wr.wr_return_amt > 0
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, hd.hd_buy_potential
    HAVING SUM(wr.wr_return_amt) > 100
),
refunded AS (
    SELECT
        c.c_customer_sk AS c_customer_sk,
        c.c_first_name AS c_first_name,
        c.c_last_name AS c_last_name,
        hd.hd_buy_potential AS hd_buy_potential,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        'refunded' AS role
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_end_date = DATE '2000-09-02'
      AND wr.wr_fee > 20
      AND c.c_birth_year > 1960
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, hd.hd_buy_potential
    HAVING SUM(wr.wr_return_amt) > 100
)
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    hd_buy_potential,
    total_return_amount,
    total_return_qty,
    role
FROM returning
UNION ALL
SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    hd_buy_potential,
    total_return_amount,
    total_return_qty,
    role
FROM refunded
ORDER BY total_return_amount DESC
LIMIT 100
