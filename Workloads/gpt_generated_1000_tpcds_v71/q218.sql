WITH cust_store AS (
    SELECT
        c.c_customer_sk,
        c.c_salutation,
        sr.sr_returned_date_sk,
        sr.sr_return_tax,
        sr.sr_return_ship_cost,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM customer c
    JOIN store_returns sr
      ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_salutation = 'Mr.'
      AND sr.sr_store_sk IN (908, 182)
      AND sr.sr_return_tax > 5.00
      AND sr.sr_return_ship_cost < 300.00
),
cust_cat AS (
    SELECT
        c.c_customer_sk,
        cr.cr_warehouse_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_order_number
    FROM customer c
    JOIN catalog_returns cr
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_amount > 100.00
)
SELECT
    w.w_warehouse_id,
    w.w_county,
    w.w_warehouse_sq_ft,
    (SELECT MAX(w2.w_warehouse_sq_ft) FROM warehouse w2) AS max_warehouse_sq_ft,
    COUNT(DISTINCT cs.sr_store_sk) AS distinct_store_count,
    SUM(cc.cr_return_amount) AS total_catalog_return_amount,
    AVG(cs.sr_return_tax) AS avg_store_return_tax,
    SUM(cc.cr_net_loss) + SUM(cs.sr_net_loss) AS total_net_loss,
    MIN(cc.cr_return_amount) AS min_return_amount,
    MAX(cc.cr_return_amount) AS max_return_amount
FROM cust_store cs
JOIN cust_cat cc
  ON cs.c_customer_sk = cc.c_customer_sk
JOIN warehouse w
  ON cc.cr_warehouse_sk = w.w_warehouse_sk
WHERE w.w_county = 'Walker County'
  AND EXISTS (
        SELECT 1
        FROM (
            SELECT DISTINCT w2.w_warehouse_id
            FROM warehouse w2
            WHERE w2.w_street_type = 'RD'
        ) dw
        WHERE dw.w_warehouse_id = w.w_warehouse_id
      )
GROUP BY w.w_warehouse_id, w.w_county, w.w_warehouse_sq_ft
ORDER BY total_net_loss DESC
LIMIT 100
