WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
ranked AS (
    SELECT
        ss.*, 
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_net_profit DESC) AS rn_profit,
        RANK() OVER (ORDER BY ss.ss_net_paid DESC) AS rank_total_paid
    FROM sampled_sales ss
)
SELECT DISTINCT
    rs.ss_sold_date_sk,
    i.i_item_id,
    c.c_customer_id,
    s.s_store_name,
    rs.ss_quantity,
    rs.ss_net_paid,
    rs.ss_net_profit,
    rs.rn_profit,
    rs.rank_total_paid,
    t.t_hour,
    hd.hd_income_band_sk,
    adr.ca_state,
    wp.wp_url,
    CASE WHEN rs.rank_total_paid <= 10 THEN 'Top10' ELSE 'Other' END AS tier,
    promo_code
FROM ranked rs
JOIN item i
  ON rs.ss_item_sk = i.i_item_sk                         -- store_sales → item
JOIN customer c
  ON rs.ss_customer_sk = c.c_customer_sk                 -- store_sales → customer
JOIN store s
  ON rs.ss_store_sk = s.s_store_sk                        -- store_sales → store
JOIN time_dim t
  ON rs.ss_sold_time_sk = t.t_time_sk                     -- store_sales → time_dim
JOIN household_demographics hd
  ON rs.ss_hdemo_sk = hd.hd_demo_sk                       -- store_sales → household_demographics
JOIN customer_address adr
  ON rs.ss_addr_sk = adr.ca_address_sk                    -- store_sales → customer_address
JOIN web_page wp
  ON c.c_customer_sk = wp.wp_customer_sk                 -- web_page → customer
LEFT JOIN store_returns sr
  ON rs.ss_item_sk = sr.sr_item_sk
     AND rs.ss_ticket_number = sr.sr_ticket_number        -- store_returns → store_sales
LEFT JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk                           -- catalog_returns → item
LEFT JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_sold_time_sk = t.t_time_sk                -- web_sales → item & time_dim
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number              -- web_returns → web_sales
CROSS JOIN UNNEST(ARRAY[rs.ss_promo_sk, ws.ws_promo_sk]) AS t(promo_code)
WHERE
    i.i_color IN ('red', 'tan')
    AND s.s_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND hd.hd_income_band_sk BETWEEN 5 AND 8
    AND rs.ss_net_profit > 0
    AND rs.rn_profit <= 5
ORDER BY rs.ss_net_profit DESC
LIMIT 100
