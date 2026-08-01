WITH
  sales_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk,
      ss.ss_item_sk,
      ss.ss_promo_sk,
      ss.ss_addr_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_ext_sales_price,
      ss.ss_ext_discount_amt,
      ss.ss_net_paid,
      ss.ss_net_profit,
      d.d_year,
      d.d_month_seq,
      s.s_store_id,
      s.s_store_name,
      s.s_state,
      p.p_promo_name,
      p.p_discount_active,
      ca.ca_city,
      ca.ca_state
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND p.p_cost > 500.00
      AND s.s_state = 'TN'
  ),

  returns_base AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_ticket_number,
      sr.sr_return_amt,
      r.r_reason_desc,
      d.d_year
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  web_returns_base AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_return_amt,
      wr.wr_reason_sk,
      ws.web_site_id,
      d.d_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),

  promo_channels AS (
    SELECT
      p.p_promo_sk,
      channel
    FROM promotion p
    CROSS JOIN UNNEST(
      ARRAY[
        CASE WHEN p.p_channel_dmail = 'Y' THEN 'dmail' END,
        CASE WHEN p.p_channel_email = 'Y' THEN 'email' END,
        CASE WHEN p.p_channel_tv = 'Y' THEN 'tv' END,
        CASE WHEN p.p_channel_radio = 'Y' THEN 'radio' END
      ]
    ) AS t(channel)
    WHERE channel IS NOT NULL
  ),

  store_common AS (
    SELECT ss_store_sk FROM sales_base
    INTERSECT
    SELECT sr_store_sk FROM returns_base
  )

SELECT
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  SUM(sb.ss_ext_sales_price) AS total_sales,
  SUM(CASE WHEN p.p_discount_active = 'Y' THEN sb.ss_ext_discount_amt ELSE 0 END) AS total_discount,
  COUNT(DISTINCT sb.ss_ticket_number) AS num_transactions,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(sb.ss_ext_sales_price) DESC) AS sales_rank,
  pc.channel,
  COUNT(*) OVER (PARTITION BY pc.channel) AS channel_txn_count
FROM sales_base sb
JOIN store s ON sb.ss_store_sk = s.s_store_sk
JOIN date_dim d ON sb.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON sb.ss_promo_sk = p.p_promo_sk
JOIN promo_channels pc ON p.p_promo_sk = pc.p_promo_sk
WHERE EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_store_sk = sb.ss_store_sk
          AND sr.sr_ticket_number = sb.ss_ticket_number
      )
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr
        JOIN date_dim wd ON wr.wr_returned_date_sk = wd.d_date_sk
        WHERE wd.d_year = d.d_year
          AND wr.wr_returning_addr_sk = sb.ss_addr_sk
      )
  AND s.s_store_sk IN (SELECT ss_store_sk FROM store_common)
  AND EXISTS (
        SELECT 1 FROM returns_base rb
        WHERE rb.sr_ticket_number = sb.ss_ticket_number
          AND rb.r_reason_desc = 'Customer Not Satisfied'
      )
GROUP BY
  s.s_store_id,
  s.s_store_name,
  d.d_year,
  pc.channel,
  p.p_discount_active
ORDER BY total_sales DESC, sales_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
