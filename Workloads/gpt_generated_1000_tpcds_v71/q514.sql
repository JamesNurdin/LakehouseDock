WITH returns_detail AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_customer_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        d.d_date,
        d.d_year,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        s.s_store_name,
        s.s_state AS store_state,
        s.s_country,
        r.r_reason_desc
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND s.s_country = 'United States'
      AND (r.r_reason_desc LIKE '%warranty%' OR r.r_reason_desc IS NULL)
)
SELECT
    s_store_name,
    store_state,
    COALESCE(r_reason_desc, 'Unknown') AS reason_desc,
    SUM(sr_return_amt) AS total_return_amt,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    CASE
        WHEN SUM(sr_return_amt) >= 10000 THEN 'High'
        WHEN SUM(sr_return_amt) >= 5000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level,
    RANK() OVER (PARTITION BY s_store_name ORDER BY SUM(sr_return_amt) DESC) AS store_return_rank
FROM returns_detail
GROUP BY
    s_store_name,
    store_state,
    COALESCE(r_reason_desc, 'Unknown')
ORDER BY total_return_amt DESC
LIMIT 100
