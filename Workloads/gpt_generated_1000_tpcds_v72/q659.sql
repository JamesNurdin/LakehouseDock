WITH sr_filtered AS (
    SELECT *
    FROM store_returns
    WHERE sr_return_ship_cost > 100.00
      AND sr_return_tax BETWEEN 5.00 AND 50.00
      AND sr_reason_sk IN (21, 29, 51)
),
joined AS (
    SELECT
        c.c_customer_id,
        st.s_store_name,
        st.s_store_id,
        cc.cc_name,
        cc.cc_employees,
        sm.sm_type,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_ticket_number,
        c.c_customer_sk
    FROM sr_filtered sr
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store st                 ON sr.sr_store_sk   = st.s_store_sk
    JOIN catalog_returns cr       ON c.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN call_center cc           ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm             ON cr.cr_ship_mode_sk   = sm.sm_ship_mode_sk
    WHERE cc.cc_gmt_offset = -5.00
      AND sm.sm_code = 'AIR       '
      AND st.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_returning_customer_sk = c.c_customer_sk
            AND cr2.cr_return_amount > 500
      )
),
agg AS (
    SELECT
        c_customer_id,
        s_store_name,
        s_store_id,
        cc_name,
        sm_type,
        cc_employees,
        c_customer_sk,
        CASE WHEN cc_employees > 200 THEN 'Large' ELSE 'Small' END AS call_center_size,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT sr_ticket_number) AS ticket_cnt,
        (
            SELECT SUM(cr3.cr_return_amount)
            FROM catalog_returns cr3
            WHERE cr3.cr_refunded_customer_sk = c_customer_sk
        ) AS cust_catalog_return_total
    FROM joined
    GROUP BY
        c_customer_id,
        s_store_name,
        s_store_id,
        cc_name,
        sm_type,
        cc_employees,
        c_customer_sk,
        CASE WHEN cc_employees > 200 THEN 'Large' ELSE 'Small' END
    HAVING SUM(sr_return_amt) > 1000
)
SELECT
    c_customer_id,
    s_store_name,
    cc_name,
    sm_type,
    call_center_size,
    total_return_amt,
    avg_return_tax,
    ticket_cnt,
    cust_catalog_return_total,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_return_amt DESC) AS rn_store
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
