/*
Goal: Identify the top 10 stores by total net loss from returns in the year 2002 where the return reason mentions "size" and the store city starts with "A". For each store, also show a concatenated label and the average numeric code extracted from promotion names that follow the pattern "Promo###" and are currently active.
*/
WITH returns_filtered AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_net_loss,
        d.d_year,
        r.r_reason_desc,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%size%'
      AND s.s_city LIKE 'A%'
)
SELECT
    rff.s_store_id,
    CONCAT(rff.s_store_name, ' - ', rff.s_city) AS store_full_label,
    SUBSTRING(rff.s_state FROM 1 FOR 2) AS state_code,
    SUM(rff.sr_net_loss) AS total_net_loss,
    (
        SELECT AVG(CAST(regexp_extract(p.p_promo_name, '(\\d+)$') AS INTEGER))
        FROM promotion p
        WHERE regexp_like(p.p_promo_name, '^Promo\\d{3}$')
          AND p.p_discount_active = 'Y'
    ) AS avg_active_promo_code
FROM returns_filtered rff
GROUP BY rff.s_store_id, rff.s_store_name, rff.s_city, rff.s_state
ORDER BY total_net_loss DESC
LIMIT 10
