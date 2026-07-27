WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
)
SELECT
    fd.d_year AS year,
    p.p_channel_tv AS promo_channel_tv,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    'Catalog' AS sales_source
FROM catalog_sales cs
JOIN filtered_dates fd ON cs.cs_sold_date_sk = fd.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE p.p_channel_tv = 'Y'
  AND hd.hd_income_band_sk = 4
GROUP BY fd.d_year, p.p_channel_tv

UNION ALL

SELECT
    fd.d_year AS year,
    p.p_channel_tv AS promo_channel_tv,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    'Store' AS sales_source
FROM store_sales ss
JOIN filtered_dates fd ON ss.ss_sold_date_sk = fd.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE p.p_channel_tv = 'Y'
  AND hd.hd_income_band_sk = 4
GROUP BY fd.d_year, p.p_channel_tv
ORDER BY year, total_net_paid_inc_tax DESC
LIMIT 100
