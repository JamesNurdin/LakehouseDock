WITH store_sales_data AS (
  SELECT
    ss.ss_ticket_number AS ticket_number,
    d.d_date AS sale_date,
    d.d_year,
    p.p_promo_name,
    p.p_channel_email,
    ss.ss_ext_sales_price AS sales_amount,
    ROW_NUMBER() OVER (PARTITION BY p.p_channel_email ORDER BY ss.ss_ext_sales_price DESC) AS rank_in_channel,
    'store' AS source
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND NOT EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = ss.ss_sold_date_sk
    )
    AND NOT EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_promo_sk = p.p_promo_sk
        AND p2.p_end_date_sk < d.d_date_sk
    )
),
web_sales_data AS (
  SELECT
    ws.ws_order_number AS ticket_number,
    d.d_date AS sale_date,
    d.d_year,
    p.p_promo_name,
    p.p_channel_email,
    ws.ws_ext_sales_price AS sales_amount,
    ROW_NUMBER() OVER (PARTITION BY p.p_channel_email ORDER BY ws.ws_ext_sales_price DESC) AS rank_in_channel,
    'web' AS source
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND p.p_discount_active = 'Y'
    AND NOT EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_promo_sk = p.p_promo_sk
        AND p2.p_end_date_sk < d.d_date_sk
    )
)
SELECT
  ticket_number,
  sale_date,
  d_year,
  p_promo_name,
  p_channel_email,
  sales_amount,
  rank_in_channel,
  source,
  (
    SELECT avg(ss2.ss_ext_sales_price)
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
  ) AS avg_year_sales
FROM (
  SELECT ticket_number, sale_date, d_year, p_promo_name, p_channel_email, sales_amount, rank_in_channel, source
  FROM store_sales_data
  UNION ALL
  SELECT ticket_number, sale_date, d_year, p_promo_name, p_channel_email, sales_amount, rank_in_channel, source
  FROM web_sales_data
) combined
ORDER BY sales_amount DESC, rank_in_channel ASC
LIMIT 100
