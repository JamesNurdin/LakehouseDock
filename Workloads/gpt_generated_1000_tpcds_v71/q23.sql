WITH sales_base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_sold_date_sk,
    cs.cs_ship_mode_sk,
    cs.cs_item_sk,
    sm.sm_carrier,
    sm.sm_type,
    i.i_item_desc,
    d.d_year
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND sm.sm_carrier LIKE 'FE%'
    AND regexp_like(i.i_item_desc, '[0-9]{2,}')
)
SELECT
  sb.sm_carrier,
  regexp_extract(sb.i_item_desc, '(\\d{2,})', 1) AS digits_in_desc,
  substr(sb.i_item_desc, 1, 10) AS short_desc,
  concat(sb.sm_carrier, '_', substr(sb.i_item_desc, 1, 5)) AS carrier_item_key,
  COUNT(*) AS sales_cnt,
  AVG(sb.cs_net_profit) AS avg_profit,
  SUM(
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_order_number = sb.cs_order_number
          AND cr.cr_return_amount > 0
      ) THEN 1 ELSE 0 END
  ) AS returns_cnt
FROM sales_base sb
GROUP BY
  sb.sm_carrier,
  regexp_extract(sb.i_item_desc, '(\\d{2,})', 1),
  substr(sb.i_item_desc, 1, 10),
  concat(sb.sm_carrier, '_', substr(sb.i_item_desc, 1, 5))
ORDER BY sales_cnt DESC
LIMIT 100
