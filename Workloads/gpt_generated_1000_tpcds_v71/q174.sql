WITH wp AS (
        SELECT wp_web_page_sk, wp_creation_date_sk, wp_type
        FROM web_page
    ),
    ws AS (
        SELECT web_site_sk, web_name, web_open_date_sk, web_state
        FROM web_site
    )
SELECT
    s.s_store_name,
    d.d_year,
    i.i_category,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions,
    AVG(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_ratio
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv
    ON inv.inv_date_sk = ss.ss_sold_date_sk
   AND inv.inv_item_sk = ss.ss_item_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
LEFT JOIN wp
    ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN ws
    ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2001 AND 2002
  AND i.i_size IN ('medium', 'large')
  AND ca.ca_gmt_offset = -5.00
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM web_returns wr_sub
        WHERE wr_sub.wr_item_sk = i.i_item_sk
          AND wr_sub.wr_returned_date_sk = d.d_date_sk
    )
GROUP BY GROUPING SETS (
        (s.s_store_name, d.d_year, i.i_category),
        (s.s_store_name, d.d_year),
        (s.s_store_name),
        ()
    )
ORDER BY total_sales DESC
LIMIT 100
