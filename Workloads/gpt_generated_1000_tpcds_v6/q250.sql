WITH base AS (
    SELECT
        c.c_customer_sk AS c_customer_sk,
        c.c_birth_year AS c_birth_year,
        c.c_birth_month AS c_birth_month,
        c.c_current_addr_sk AS c_current_addr_sk,
        sr.sr_return_quantity AS sr_return_quantity,
        sr.sr_return_amt AS sr_return_amt,
        r.r_reason_desc AS r_reason_desc,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        sm.sm_carrier AS sm_carrier,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_order_number AS ws_order_number,
        w.web_state AS web_state,
        wr.wr_return_ship_cost AS wr_return_ship_cost,
        wr.wr_return_amt AS wr_return_amt
    FROM customer c
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
)
SELECT
    r_reason_desc,
    sm_carrier,
    web_state,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(sr_return_amt) AS total_store_return_amount,
    AVG(wr_return_ship_cost) AS avg_web_return_ship_cost,
    CASE
        WHEN SUM(cr_return_amount) > 10000 THEN 'HIGH'
        WHEN SUM(cr_return_amount) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_volume_category,
    (
        SELECT AVG(cr_net_loss)
        FROM catalog_returns
        WHERE cr_reason_sk = (
            SELECT r_reason_sk
            FROM reason
            WHERE r_reason_desc = 'Package was damaged'
        )
    ) AS avg_loss_for_damaged
FROM base
WHERE c_birth_year BETWEEN 1970 AND 1990
  AND c_birth_month IN (5, 6, 7)
  AND c_current_addr_sk > 500000
  AND sr_return_quantity >= 2
  AND cr_return_quantity <= 5
  AND wr_return_ship_cost BETWEEN 100 AND 800
  AND sm_carrier = 'UPS'
  AND web_state = 'CA'
GROUP BY r_reason_desc, sm_carrier, web_state
ORDER BY total_catalog_return_amount DESC
LIMIT 100
