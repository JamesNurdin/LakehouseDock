WITH inv_agg AS (
    SELECT
        i.inv_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_qty
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    GROUP BY i.inv_warehouse_sk, d.d_year, d.d_month_seq
),
promo_filt AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_channel_dmail,
        p.p_channel_radio
    FROM promotion p
    WHERE regexp_like(p.p_channel_dmail, '^Y')
      AND p.p_channel_radio = 'N'
      AND p.p_promo_name LIKE '%Summer%'
),
promo_start AS (
    SELECT
        p.p_promo_sk,
        d.d_month_seq AS start_month_seq,
        d.d_year AS start_year
    FROM promo_filt p
    JOIN date_dim d
        ON p.p_start_date_sk = d.d_date_sk
),
promo_end AS (
    SELECT
        p.p_promo_sk,
        d.d_month_seq AS end_month_seq,
        d.d_year AS end_year
    FROM promo_filt p
    JOIN date_dim d
        ON p.p_end_date_sk = d.d_date_sk
)
SELECT
    w.w_warehouse_name,
    ia.d_year,
    ia.d_month_seq,
    ia.total_qty,
    pf.p_promo_name,
    CONCAT(w.w_city, ' - ', pf.p_promo_name) AS city_promo,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY ia.total_qty DESC) AS rn
FROM inv_agg ia
JOIN warehouse w
    ON ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN promo_filt pf
    ON 1 = 1
JOIN promo_start ps
    ON pf.p_promo_sk = ps.p_promo_sk
JOIN promo_end pe
    ON pf.p_promo_sk = pe.p_promo_sk
WHERE
    ia.d_month_seq BETWEEN ps.start_month_seq AND pe.end_month_seq
    AND w.w_street_name LIKE '%Elm%'
    AND regexp_like(w.w_city, '^R')
ORDER BY ia.total_qty DESC, w.w_warehouse_name
LIMIT 100
