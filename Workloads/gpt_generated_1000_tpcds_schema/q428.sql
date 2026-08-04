WITH
    sales_agg AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_bill_customer_sk,
            cs.cs_ship_date_sk,
            cs.cs_call_center_sk,
            cs.cs_ship_mode_sk,
            cs.cs_warehouse_sk,
            cs.cs_bill_addr_sk,
            SUM(cs.cs_net_paid) AS sum_net_paid,
            SUM(cs.cs_quantity) AS sum_quantity,
            AVG(cs.cs_coupon_amt) AS avg_coupon
        FROM tpcds.catalog_sales cs
        JOIN tpcds.date_dim d ON cs.cs_ship_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND cs.cs_quantity > 5
          AND cs.cs_net_paid > 1000
        GROUP BY
            cs.cs_item_sk,
            cs.cs_bill_customer_sk,
            cs.cs_ship_date_sk,
            cs.cs_call_center_sk,
            cs.cs_ship_mode_sk,
            cs.cs_warehouse_sk,
            cs.cs_bill_addr_sk
    ),
    returns_agg AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_customer_sk,
            sr.sr_returned_date_sk,
            sr.sr_reason_sk,
            SUM(sr.sr_return_amt) AS sum_return_amt,
            SUM(sr.sr_return_quantity) AS sum_return_qty
        FROM tpcds.store_returns sr
        JOIN tpcds.date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
          AND sr.sr_return_quantity < 10
        GROUP BY
            sr.sr_item_sk,
            sr.sr_customer_sk,
            sr.sr_returned_date_sk,
            sr.sr_reason_sk
    ),
    sales_customers AS (
        SELECT DISTINCT cs_bill_customer_sk AS c_customer_sk
        FROM sales_agg
    ),
    returns_customers AS (
        SELECT DISTINCT sr_customer_sk AS c_customer_sk
        FROM returns_agg
    ),
    customers_no_returns AS (
        SELECT sc.c_customer_sk
        FROM sales_customers sc
        EXCEPT
        SELECT rc.c_customer_sk
        FROM returns_customers rc
    )
SELECT
    c.c_customer_id,
    i.i_item_id,
    w.w_warehouse_name,
    cc.cc_name,
    sm.sm_carrier,
    r.r_reason_desc,
    CASE
        WHEN sa.sum_net_paid - ra.sum_return_amt > 0 THEN 'PROFIT'
        ELSE 'LOSS'
    END AS profit_flag,
    sa.sum_net_paid,
    ra.sum_return_amt,
    (sa.sum_net_paid - ra.sum_return_amt) AS net_after_returns,
    ld.max_discount,
    ca.ca_city
FROM sales_agg sa
JOIN returns_agg ra
    ON sa.cs_item_sk = ra.sr_item_sk
   AND sa.cs_bill_customer_sk = ra.sr_customer_sk
   AND sa.cs_ship_date_sk = ra.sr_returned_date_sk
JOIN tpcds.item i
    ON sa.cs_item_sk = i.i_item_sk
JOIN tpcds.warehouse w
    ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.call_center cc
    ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.reason r
    ON ra.sr_reason_sk = r.r_reason_sk
JOIN tpcds.customer c
    ON sa.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON sa.cs_bill_addr_sk = ca.ca_address_sk
JOIN LATERAL (
    SELECT MAX(cs2.cs_ext_discount_amt) AS max_discount
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = sa.cs_bill_customer_sk
) ld ON TRUE
WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM customers_no_returns)
  AND c.c_birth_year BETWEEN 1950 AND 1960
  AND ca.ca_gmt_offset BETWEEN -5 AND 5
  AND w.w_warehouse_sq_ft > 5000
  AND cc.cc_gmt_offset > 0
  AND sm.sm_contract LIKE 'P7FB%'
ORDER BY net_after_returns DESC
LIMIT 100
