WITH filtered_date AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    fd.d_year AS year,
    ca.ca_state AS state,
    cd.cd_gender AS gender,
    r.r_reason_desc AS return_reason,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_cnt,
    SUM(p.p_cost) AS total_promo_cost
FROM store_returns sr
JOIN filtered_date fd ON sr.sr_returned_date_sk = fd.d_date_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN promotion p ON p.p_start_date_sk = fd.d_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = fd.d_date_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = fd.d_date_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_purchase_estimate >= 5000
  AND ca.ca_state = 'CA'
  AND r.r_reason_desc LIKE '%unauthor%'
GROUP BY fd.d_year, ca.ca_state, cd.cd_gender, r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
