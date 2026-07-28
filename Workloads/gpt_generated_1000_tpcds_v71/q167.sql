WITH joined_data AS (
  SELECT
    d.d_year,
    c.c_customer_id,
    ss.ss_net_paid,
    ss.ss_net_profit,
    sr.sr_net_loss AS store_return_loss,
    wr.wr_net_loss AS web_return_loss,
    p.p_channel_dmail,
    c.c_birth_country,
    wp.wp_image_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN web_returns wr ON r.r_reason_sk = wr.wr_reason_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
  WHERE c.c_birth_country = 'CHILE'
    AND p.p_channel_dmail = 'Y'
    AND d.d_year BETWEEN 2000 AND 2002
    AND wp.wp_image_count >= 3
),
agg_data AS (
  SELECT
    d_year,
    c_customer_id,
    SUM(ss_net_paid) AS total_sales,
    SUM(store_return_loss) AS total_store_returns,
    SUM(web_return_loss) AS total_web_returns,
    SUM(ss_net_profit) AS total_profit
  FROM joined_data
  GROUP BY d_year, c_customer_id
)
SELECT
  d_year,
  c_customer_id,
  total_sales,
  total_store_returns,
  total_web_returns,
  total_profit,
  RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM agg_data
ORDER BY d_year, sales_rank
LIMIT 100
