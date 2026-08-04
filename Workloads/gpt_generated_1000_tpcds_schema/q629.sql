WITH promo_sub AS (
  SELECT
    p.p_promo_id AS id,
    i.i_item_id AS related_id,
    d.d_date AS ref_date,
    p.p_cost AS amount,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS status,
    SUM(p.p_cost) OVER (PARTITION BY i.i_item_id ORDER BY d.d_date
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amount
  FROM promotion p
  JOIN item i ON p.p_item_sk = i.i_item_sk
  JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
  WHERE p.p_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_brand = 'Brand#23')
    AND p.p_channel_catalog = 'N'
),
site_sub AS (
  SELECT
    w.web_site_id AS id,
    w.web_name AS related_id,
    d.d_date AS ref_date,
    CAST(NULL AS decimal(15,2)) AS amount,
    CASE WHEN w.web_state = 'CA' THEN 'West' ELSE 'Other' END AS status,
    CAST(NULL AS decimal(15,2)) AS cum_amount
  FROM web_site w
  JOIN date_dim d ON w.web_open_date_sk = d.d_date_sk
  WHERE w.web_open_date_sk IN (SELECT d2.d_date_sk FROM date_dim d2 WHERE d2.d_year = 2000)
    AND w.web_city LIKE 'San%'
)
SELECT DISTINCT id, related_id, ref_date, amount, status, cum_amount
FROM (
  SELECT id, related_id, ref_date, amount, status, cum_amount FROM promo_sub
  UNION ALL
  SELECT id, related_id, ref_date, amount, status, cum_amount FROM site_sub
) combined
ORDER BY ref_date DESC
LIMIT 100
