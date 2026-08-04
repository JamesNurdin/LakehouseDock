WITH cs_detail AS (
    SELECT
        cs_sold_time_sk,
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*)        AS sales_cnt
    FROM catalog_sales
    WHERE cs_net_profit > (
        SELECT AVG(cs_net_profit) FROM catalog_sales
    )
    GROUP BY cs_sold_time_sk, cs_bill_customer_sk
),
cust_filtered AS (
    SELECT
        c_customer_sk,
        c_email_address,
        c_customer_id,
        regexp_extract(c_customer_id, '(A{5})(.*)', 2) AS id_suffix
    FROM customer
    WHERE regexp_like(c_email_address, '^.*@example\\.(com|net)$')
      AND c_customer_id LIKE 'AAAAA%'
)
SELECT
    t.t_time_id,
    t.t_hour,
    t.t_minute,
    cf.c_customer_id,
    cf.id_suffix,
    d.total_net_profit,
    d.sales_cnt,
    regexp_extract(t.t_time_id, 'A{3}(.*)A{5}', 1) AS time_id_middle
FROM time_dim t
RIGHT OUTER JOIN cs_detail d
    ON d.cs_sold_time_sk = t.t_time_sk
LEFT JOIN cust_filtered cf
    ON cf.c_customer_sk = d.cs_bill_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    WHERE ws.ws_sold_time_sk = t.t_time_sk
      AND ws.ws_net_profit > 0
)
ORDER BY d.total_net_profit DESC NULLS LAST,
         t.t_hour ASC
OFFSET 0 LIMIT 100
