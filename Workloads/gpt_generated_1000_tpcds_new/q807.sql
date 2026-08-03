WITH sales_by_customer AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_paid,
        SUM(ws.ws_ext_ship_cost) AS total_ship
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451393 AND 2451796
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
returns_by_customer AS (
    SELECT
        cust.c_customer_sk,
        cust.c_first_name,
        cust.c_last_name,
        SUM(wr.wr_return_amt) AS total_return,
        SUM(wr.wr_refunded_cash) AS total_refund
    FROM web_returns wr
    JOIN customer cust
        ON wr.wr_refunded_customer_sk = cust.c_customer_sk
    WHERE wr.wr_return_amt > 20
    GROUP BY cust.c_customer_sk, cust.c_first_name, cust.c_last_name
),
combined AS (
    SELECT
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_paid,
        s.total_ship,
        COALESCE(r.total_return, 0) AS total_return,
        COALESCE(r.total_refund, 0) AS total_refund
    FROM sales_by_customer s
    FULL OUTER JOIN returns_by_customer r
        ON s.c_customer_sk = r.c_customer_sk
),
net_contrib AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.total_paid - c.total_refund AS net_amount,
        l.detail
    FROM combined c
    LEFT JOIN LATERAL (
        SELECT concat('Net_', CAST(c.c_customer_sk AS varchar)) AS detail
    ) l ON true
)
SELECT nc.c_customer_sk, nc.c_first_name, nc.c_last_name, nc.net_amount, nc.detail
FROM net_contrib nc
WHERE nc.net_amount > 0

UNION

SELECT nc.c_customer_sk, nc.c_first_name, nc.c_last_name, nc.net_amount, nc.detail
FROM net_contrib nc
WHERE nc.net_amount <= 0
  AND nc.c_customer_sk IN (
      SELECT c.c_customer_sk
      FROM customer c
      WHERE c.c_preferred_cust_flag = 'Y'
  )

EXCEPT

SELECT nc.c_customer_sk, nc.c_first_name, nc.c_last_name, nc.net_amount, nc.detail
FROM net_contrib nc
WHERE nc.c_customer_sk IN (
      SELECT wr.wr_returning_customer_sk
      FROM web_returns wr
      WHERE wr.wr_return_amt > 100
)
LIMIT 100
