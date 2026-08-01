WITH filtered_ship_modes AS (
    SELECT
        sm_ship_mode_sk,
        sm_ship_mode_id,
        sm_contract,
        sm_code,
        regexp_extract(sm_contract, '(\\d+)', 1) AS contract_number,
        substring(sm_code FROM 1 FOR 3) AS code_prefix
    FROM ship_mode
    WHERE regexp_like(sm_contract, '^GNJ')
      AND sm_code LIKE '%AIR%'
)
SELECT
    d.d_year,
    d.d_month_seq,
    concat(fs.code_prefix, '-', fs.contract_number) AS ship_contract_key,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(p.p_promo_name) AS sample_promo_name
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN filtered_ship_modes fs
    ON cr.cr_ship_mode_sk = fs.sm_ship_mode_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN promotion p
    ON d.d_date_sk = p.p_start_date_sk
WHERE d.d_year = 2002
  AND t.t_hour BETWEEN 8 AND 20
  AND p.p_promo_name LIKE '%Spring%'
GROUP BY
    d.d_year,
    d.d_month_seq,
    fs.code_prefix,
    fs.contract_number
ORDER BY total_return_amount DESC
LIMIT 100
