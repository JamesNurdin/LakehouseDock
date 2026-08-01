WITH promo_dates AS (
    SELECT p.p_promo_sk,
           d.d_date_sk,
           d.d_year,
           d.d_quarter_seq,
           SPLIT(p.p_channel_details, ',') AS channel_arr
    FROM promotion p
    JOIN date_dim d
      ON p.p_start_date_sk = d.d_date_sk
    WHERE p.p_channel_dmail = 'Y'
      AND d.d_year BETWEEN 2000 AND 2002
),
promo_channels AS (
    SELECT pd.p_promo_sk,
           pd.d_date_sk,
           pd.d_year,
           pd.d_quarter_seq,
           ch AS channel
    FROM promo_dates pd
    CROSS JOIN UNNEST(pd.channel_arr) AS t(ch)
),
store_active AS (
    SELECT s.s_store_sk,
           s.s_store_id,
           d.d_date_sk,
           d.d_year,
           d.d_quarter_seq
    FROM store s
    JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
web_active AS (
    SELECT w.web_site_sk,
           w.web_site_id,
           d.d_date_sk,
           d.d_year,
           d.d_quarter_seq
    FROM web_site w
    JOIN date_dim d
      ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
intersect_dates AS (
    SELECT d_date_sk
    FROM store_active
    INTERSECT
    SELECT d_date_sk
    FROM promo_dates
),
valid_dates AS (
    SELECT d_date_sk
    FROM intersect_dates
    EXCEPT
    SELECT d.d_date_sk
    FROM store s
    JOIN date_dim d
      ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_closed_date_sk IS NOT NULL
)
SELECT
    sa.s_store_id   AS entity_id,
    'store'         AS entity_type,
    pc.d_year,
    pc.d_quarter_seq,
    pc.channel,
    COUNT(*)        AS promo_count
FROM store_active sa
JOIN promo_channels pc
  ON sa.d_date_sk = pc.d_date_sk
JOIN valid_dates vd
  ON pc.d_date_sk = vd.d_date_sk
GROUP BY sa.s_store_id, pc.d_year, pc.d_quarter_seq, pc.channel
UNION
SELECT
    wa.web_site_id AS entity_id,
    'web_site'    AS entity_type,
    pc.d_year,
    pc.d_quarter_seq,
    pc.channel,
    COUNT(*)      AS promo_count
FROM web_active wa
JOIN promo_channels pc
  ON wa.d_date_sk = pc.d_date_sk
JOIN valid_dates vd
  ON pc.d_date_sk = vd.d_date_sk
GROUP BY wa.web_site_id, pc.d_year, pc.d_quarter_seq, pc.channel
ORDER BY entity_type, entity_id, d_year, d_quarter_seq
LIMIT 100
