WITH
  sales_data AS (
    SELECT DISTINCT
      COALESCE(s.s_store_name, 'UNKNOWN') AS s_store_name,
      d.d_year,
      COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS ticket_number,
      COALESCE(ss.ss_ext_sales_price, 0) AS ss_ext_sales_price,
      COALESCE(ss.ss_net_paid, 0) AS ss_net_paid,
      COALESCE(sr.sr_net_loss, 0) AS net_loss,
      CASE
        WHEN ss.ss_ticket_number IS NOT NULL THEN 'SALE'
        WHEN sr.sr_ticket_number IS NOT NULL THEN 'RETURN'
        ELSE 'UNKNOWN'
      END AS trans_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    FULL OUTER JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
      AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
  ),
  returns_data AS (
    SELECT DISTINCT
      NULL AS s_store_name,
      d.d_year,
      cr.cr_order_number AS ticket_number,
      cr.cr_return_amount AS ss_ext_sales_price,
      cr.cr_refunded_cash AS ss_net_paid,
      cr.cr_net_loss AS net_loss,
      'RETURN' AS trans_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
  ),
  combined AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
  )
SELECT
  COALESCE(s_store_name, 'ALL_STORES') AS store_name,
  d_year,
  SUM(ss_ext_sales_price) AS total_sales_amount,
  SUM(net_loss) AS total_net_loss,
  COUNT(DISTINCT ticket_number) AS unique_tickets,
  SUM(CASE WHEN trans_type = 'SALE' THEN ss_ext_sales_price ELSE -ss_ext_sales_price END) AS net_revenue
FROM combined
GROUP BY CUBE(s_store_name, d_year)
ORDER BY store_name, d_year
LIMIT 100
