WITH web_sales_agg AS (
    SELECT d.d_date AS sale_date,
           sum(ws.ws_net_paid) AS total_net_paid,
           count(*) AS num_sales,
           max(regexp_extract(p.p_promo_name, '(\\d{4})', 1)) AS promo_year_extracted,
           min(substring(sm.sm_carrier, 1, 3)) AS carrier_prefix
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE sm.sm_type LIKE '%AIR%'
      AND regexp_like(p.p_promo_name, '.*Sale.*')
    GROUP BY d.d_date
),
store_returns_agg AS (
    SELECT d.d_date AS return_date,
           sum(sr.sr_net_loss) AS total_net_loss,
           count(*) AS num_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_country LIKE 'United%'
      AND (s.s_city LIKE 'A%' OR s.s_city LIKE '%ville')
    GROUP BY d.d_date
)
SELECT
    COALESCE(ws.sale_date, sr.return_date) AS the_date,
    ws.total_net_paid,
    ws.num_sales,
    ws.promo_year_extracted,
    ws.carrier_prefix,
    sr.total_net_loss,
    sr.num_returns,
    concat('Date:', cast(COALESCE(ws.sale_date, sr.return_date) AS varchar)) AS date_label
FROM web_sales_agg ws
FULL OUTER JOIN store_returns_agg sr
    ON ws.sale_date = sr.return_date
WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p3
    JOIN date_dim d3 ON p3.p_start_date_sk = d3.d_date_sk
    WHERE d3.d_date = COALESCE(ws.sale_date, sr.return_date)
      AND p3.p_discount_active = 'Y'
)
ORDER BY the_date
LIMIT 100
