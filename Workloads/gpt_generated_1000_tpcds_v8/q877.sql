WITH sampled_warehouse AS (
    SELECT w_warehouse_sk,
           w_warehouse_name,
           w_city,
           w_suite_number
    FROM warehouse TABLESAMPLE BERNOULLI (20)
    WHERE w_suite_number LIKE 'Suite %'
      AND regexp_like(w_city, '^A')
),

high_income_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 100000
),

store_only_customers AS (
    SELECT DISTINCT sr.sr_customer_sk AS cust_sk
    FROM store_returns sr
    EXCEPT
    SELECT DISTINCT cr.cr_refunded_customer_sk AS cust_sk
    FROM catalog_returns cr
),

catalog_ship AS (
    SELECT cr.cr_refunded_customer_sk AS cust_sk,
           sm.sm_type,
           w.w_warehouse_sk,
           w.w_warehouse_name,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 0
)
SELECT
    COALESCE(sr.sr_customer_sk, c.c_customer_sk)                           AS customer_sk,
    CASE
        WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(cs.net_loss, 0) > 200 THEN 'High'
        ELSE 'Low'
    END                                                                      AS loss_category,
    fn.full_name,
    ca.ca_city,
    LENGTH(ca.ca_city)                                                      AS city_len,
    regexp_extract(ca.ca_city, '([A-Z][a-z]+)', 1)                         AS city_first_word,
    cs.sm_type,
    cs.w_warehouse_name,
    sw.w_city                                                                AS sampled_city,
    (SELECT COUNT(*) FROM store_only_customers)                           AS store_only_customer_cnt
FROM store_returns sr
FULL OUTER JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca
    ON COALESCE(sr.sr_addr_sk, c.c_current_addr_sk) = ca.ca_address_sk
CROSS JOIN LATERAL (
    SELECT concat(c.c_first_name, ' ', c.c_last_name) AS full_name
) AS fn
LEFT JOIN catalog_ship cs
    ON COALESCE(sr.sr_customer_sk, c.c_customer_sk) = cs.cust_sk
LEFT JOIN sampled_warehouse sw
    ON cs.w_warehouse_sk = sw.w_warehouse_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM high_income_customers hic
        WHERE hic.c_customer_sk = COALESCE(sr.sr_customer_sk, c.c_customer_sk)
    )
  AND (ca.ca_city LIKE '%ville' OR ca.ca_city IS NULL)
GROUP BY
    COALESCE(sr.sr_customer_sk, c.c_customer_sk),
    CASE
        WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(cs.net_loss, 0) > 200 THEN 'High'
        ELSE 'Low'
    END,
    fn.full_name,
    ca.ca_city,
    LENGTH(ca.ca_city),
    regexp_extract(ca.ca_city, '([A-Z][a-z]+)', 1),
    cs.sm_type,
    cs.w_warehouse_name,
    sw.w_city
ORDER BY loss_category DESC, store_only_customer_cnt DESC
LIMIT 100
