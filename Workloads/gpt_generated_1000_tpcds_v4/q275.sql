WITH filtered_date AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2000
),
filtered_item AS (
    SELECT *
    FROM item
    WHERE i_category = 'Sports'
),
filtered_reason AS (
    SELECT *
    FROM reason
    WHERE r_reason_desc LIKE '%price%'
)
SELECT
    s.s_store_name,
    d.d_year,
    i.i_category,
    r.r_reason_desc,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txns,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_txns,
    wp.wp_url,
    ws.web_name
FROM filtered_date d
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN filtered_item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
JOIN filtered_reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d.d_date_sk
 AND cs.cs_item_sk = i.i_item_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
 AND wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE r.r_reason_desc LIKE '%price%'
GROUP BY
    s.s_store_name,
    d.d_year,
    i.i_category,
    r.r_reason_desc,
    wp.wp_url,
    ws.web_name
ORDER BY total_sales DESC
LIMIT 100
