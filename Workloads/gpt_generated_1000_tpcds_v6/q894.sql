WITH filtered AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_reason_sk,
        sr.sr_return_time_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_ticket_number
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE i.i_color = 'royal'
      AND i.i_brand_id IN (1002001, 8015002)
      AND r.r_reason_desc LIKE '%color%'
      AND ib.ib_lower_bound >= 50000
      AND s.s_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
),
distinct_brands AS (
    SELECT DISTINCT i.i_brand, i.i_color
    FROM item i
    WHERE i.i_color = 'royal'
)
SELECT
    s.s_store_name,
    i.i_brand,
    i.i_color,
    SUM(f.sr_return_amt) AS total_return_amount,
    AVG(f.sr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT f.sr_ticket_number) AS distinct_tickets,
    GROUPING(s.s_store_name) AS grp_store,
    GROUPING(i.i_brand) AS grp_brand,
    GROUPING(i.i_color) AS grp_color
FROM filtered f
JOIN store s ON f.sr_store_sk = s.s_store_sk
JOIN item i ON f.sr_item_sk = i.i_item_sk
JOIN household_demographics hd ON f.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN reason r ON f.sr_reason_sk = r.r_reason_sk
JOIN time_dim t ON f.sr_return_time_sk = t.t_time_sk
JOIN distinct_brands db ON i.i_brand = db.i_brand AND i.i_color = db.i_color
GROUP BY GROUPING SETS (
    (s.s_store_name, i.i_brand, i.i_color),
    (s.s_store_name, i.i_brand),
    (s.s_store_name),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
