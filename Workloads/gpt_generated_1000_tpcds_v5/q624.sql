WITH returned AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_addr_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d.d_date,
        ca.ca_city,
        ca.ca_state
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
)
SELECT
    r.ca_city,
    r.ca_state,
    ws.web_name,
    ws.web_market_manager,
    concat(ws.web_city, ', ', ws.web_state) AS site_location,
    regexp_extract(ws.web_name, '(Online|Site)', 1) AS site_type,
    SUM(r.sr_return_amt) AS total_return_amt,
    COUNT(*) AS return_cnt,
    CASE
        WHEN SUM(r.sr_return_amt) > 1000 THEN 'High'
        ELSE 'Low'
    END AS return_level,
    ROW_NUMBER() OVER (PARTITION BY r.ca_city ORDER BY SUM(r.sr_return_amt) DESC) AS rn,
    (SELECT SUM(sr2.sr_return_amt) FROM store_returns sr2) AS overall_total_return
FROM returned r
JOIN web_site ws ON ws.web_open_date_sk = r.sr_returned_date_sk
WHERE regexp_like(ws.web_name, '^.*(Online|Site).*$')
  AND ws.web_market_manager LIKE '%John%'
  AND substring(ws.web_city, 1, 1) = 'S'
GROUP BY
    r.ca_city,
    r.ca_state,
    ws.web_name,
    ws.web_market_manager,
    ws.web_city,
    ws.web_state
HAVING COUNT(*) > 5
ORDER BY total_return_amt DESC
LIMIT 100
