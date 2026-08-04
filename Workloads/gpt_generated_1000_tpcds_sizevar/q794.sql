WITH new_stores AS (
    SELECT s.s_store_sk
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    EXCEPT
    SELECT s.s_store_sk
    FROM store s
    JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
computed_set AS (
    SELECT 'Low' AS risk_level UNION ALL SELECT 'Medium' UNION ALL SELECT 'High'
)
SELECT
    d.d_year,
    i.i_category,
    s.s_store_name,
    cs.risk_level,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt,
    MIN(sr.sr_return_tax) AS min_return_tax,
    MAX(i.i_current_price) AS max_item_price,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customer_returns,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN sr.sr_return_amt ELSE 0 END) AS discount_return_amount
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
JOIN new_stores ns ON s.s_store_sk = ns.s_store_sk
CROSS JOIN computed_set cs
WHERE d.d_year = 2001
  AND i.i_brand_id IN (6, 27)
  AND t.t_hour BETWEEN 9 AND 17
  AND ca.ca_state = 'CA'
GROUP BY CUBE (d.d_year, i.i_category, s.s_store_name, cs.risk_level)
ORDER BY total_return_amount DESC
LIMIT 100
