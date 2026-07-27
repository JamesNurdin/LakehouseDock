WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt) AS store_date_return_amt,
        SUM(sr.sr_return_quantity) AS store_date_return_qty,
        COUNT(DISTINCT sr.sr_item_sk) AS store_date_distinct_items
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
    GROUP BY sr.sr_store_sk, sr.sr_addr_sk, sr.sr_returned_date_sk
)
SELECT
    d.d_year,
    d.d_quarter_name,
    ca.ca_state,
    s.s_store_name,
    w.w_county,
    p.p_purpose,
    SUM(sr_agg.store_date_return_amt) AS total_return_amt,
    SUM(sr_agg.store_date_return_qty) AS total_return_qty,
    COUNT(DISTINCT sr_agg.sr_store_sk) AS stores_involved,
    CASE
        WHEN SUM(sr_agg.store_date_return_amt) > 10000 THEN 'Very High'
        WHEN SUM(sr_agg.store_date_return_amt) > 5000 THEN 'High'
        ELSE 'Normal'
    END AS return_level,
    (SELECT COUNT(*)
     FROM promotion p2
     WHERE p2.p_response_target = 1
       AND p2.p_start_date_sk = d.d_date_sk) AS promo_response_target_cnt
FROM sr_agg
JOIN date_dim d ON sr_agg.sr_returned_date_sk = d.d_date_sk
JOIN customer_address ca ON sr_agg.sr_addr_sk = ca.ca_address_sk
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
WHERE
    d.d_year = 1998
    AND ca.ca_state = 'CA'
    AND w.w_county = 'Mobile County'
    AND s.s_state = 'TX'
    AND p.p_purpose = 'Unknown'
GROUP BY
    d.d_year,
    d.d_quarter_name,
    ca.ca_state,
    s.s_store_name,
    w.w_county,
    p.p_purpose,
    d.d_date_sk
HAVING
    SUM(sr_agg.store_date_return_amt) > 2000
ORDER BY
    total_return_amt DESC,
    d.d_year,
    d.d_quarter_name
LIMIT 100
