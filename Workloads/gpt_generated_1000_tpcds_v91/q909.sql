WITH promo_items AS (
    SELECT
        p.p_item_sk,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_promo_name
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
      AND regexp_like(p.p_promo_name, 'Clearance')
)
SELECT
    d.d_year,
    s.s_state,
    CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_amount_category,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    regexp_extract(i.i_product_name, '^([A-Za-z]+)', 1) AS product_name_prefix,
    CONCAT(s.s_store_name, ' (', s.s_city, ')') AS store_full_name
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
JOIN promo_items pi ON i.i_item_sk = pi.p_item_sk
WHERE s.s_state LIKE 'C%'
  AND i.i_product_name LIKE 'Chocolate%'
  AND s.s_store_sk IN (
        SELECT s2.s_store_sk
        FROM store s2
        WHERE s2.s_city LIKE '%City%'
    )
GROUP BY
    d.d_year,
    s.s_state,
    CASE WHEN sr.sr_return_amt > 100 THEN 'High' ELSE 'Low' END,
    regexp_extract(i.i_product_name, '^([A-Za-z]+)', 1),
    CONCAT(s.s_store_name, ' (', s.s_city, ')')
ORDER BY total_return_amount DESC
LIMIT 100
