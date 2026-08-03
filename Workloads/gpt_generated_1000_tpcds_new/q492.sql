WITH
  wp_sample AS (
    SELECT *
    FROM web_page
    TABLESAMPLE BERNOULLI (10)
  ),
  base AS (
    SELECT
      d.d_date,
      d.d_year,
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      ss.ss_item_sk,
      ss.ss_net_paid,
      ws.ws_net_paid,
      sr.sr_return_quantity,
      r.r_reason_desc,
      i.inv_quantity_on_hand,
      wp_sample.wp_type,
      wp_sample.wp_url,
      we.web_name
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN store s ON s.s_store_sk = COALESCE(ss.ss_store_sk, sr.sr_store_sk)
    LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN wp_sample ON wp_sample.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site we ON we.web_site_sk = ws.ws_web_site_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'TX'
      AND wp_sample.wp_type = 'welcome'
      AND i.inv_quantity_on_hand > 0
      AND r.r_reason_desc LIKE '%damaged%'
      AND NOT EXISTS (
        SELECT 1
        FROM inventory i2
        WHERE i2.inv_item_sk = ss.ss_item_sk
          AND i2.inv_quantity_on_hand < 0
      )
  ),
  agg AS (
    SELECT
      s_store_sk,
      s_store_name,
      s_state,
      SUM(COALESCE(ss_net_paid, 0) + COALESCE(ws_net_paid, 0)) AS total_net_paid
    FROM base
    GROUP BY s_store_sk, s_store_name, s_state
  )
SELECT
  a.s_store_name,
  a.s_state,
  a.total_net_paid,
  RANK() OVER (ORDER BY a.total_net_paid DESC) AS revenue_rank,
  CASE WHEN a.total_net_paid > 10000 THEN 'High' ELSE 'Low' END AS revenue_category,
  dim_state.state,
  gen.letter
FROM agg a
CROSS JOIN (
  SELECT DISTINCT s_state AS state
  FROM store
  WHERE s_state IS NOT NULL
) dim_state
CROSS JOIN (VALUES 'A', 'B', 'C') AS gen(letter)
ORDER BY revenue_rank
LIMIT 100
