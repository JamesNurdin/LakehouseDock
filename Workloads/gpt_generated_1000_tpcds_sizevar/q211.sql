WITH date_sales AS (
    SELECT d_date_sk, d_year, d_month_seq, d_date
    FROM date_dim
),
promo_tokens AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           split(p.p_promo_name, ' ') AS tokens
    FROM promotion p
),
promo_unnested AS (
    SELECT pt.p_promo_sk,
           pt.p_promo_name,
           t.token
    FROM promo_tokens pt
    CROSS JOIN UNNEST(pt.tokens) AS t(token)
),
joined AS (
   SELECT
       ss.ss_sold_date_sk,
       ds.d_year,
       ds.d_month_seq,
       ss.ss_item_sk,
       ss.ss_quantity,
       ss.ss_sales_price,
       ss.ss_net_profit,
       ca.ca_state,
       hd.hd_income_band_sk,
       ib.ib_upper_bound,
       pu.token,
       ws.ws_order_number,
       ws.ws_quantity AS ws_quantity,
       ws.ws_sales_price AS ws_sales_price,
       w.w_warehouse_name,
       wp.wp_type,
       ws_site.web_name
   FROM store_sales ss
   JOIN date_sales ds
     ON ss.ss_sold_date_sk = ds.d_date_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   JOIN promo_unnested pu
     ON p.p_promo_sk = pu.p_promo_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN web_sales ws
     ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
   LEFT JOIN date_dim d_ws
     ON ws.ws_sold_date_sk = d_ws.d_date_sk
   LEFT JOIN warehouse w
     ON ws.ws_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_site ws_site
     ON ws.ws_web_site_sk = ws_site.web_site_sk
   WHERE EXISTS (
       SELECT 1
       FROM catalog_page cp
       WHERE cp.cp_catalog_page_number = 14
         AND (cp.cp_start_date_sk = ss.ss_sold_date_sk OR cp.cp_end_date_sk = ss.ss_sold_date_sk)
   )
),
aggregated AS (
   SELECT
       ss_sold_date_sk,
       d_year,
       d_month_seq,
       ca_state,
       hd_income_band_sk,
       ib_upper_bound,
       token,
       SUM(ss_sales_price) AS total_sales_price,
       SUM(ss_net_profit) AS total_net_profit
   FROM joined
   GROUP BY
       ss_sold_date_sk,
       d_year,
       d_month_seq,
       ca_state,
       hd_income_band_sk,
       ib_upper_bound,
       token
   HAVING SUM(ss_sales_price) > 1000
),
ranked AS (
   SELECT
       a.*,
       SUM(total_sales_price) OVER (PARTITION BY d_year ORDER BY d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_ytd,
       LAG(total_sales_price) OVER (PARTITION BY ca_state ORDER BY d_year, d_month_seq) AS prev_state_sales,
       ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_sales_price DESC) AS state_rank
   FROM aggregated a
)
SELECT
    ss_sold_date_sk,
    d_year,
    d_month_seq,
    ca_state,
    hd_income_band_sk,
    ib_upper_bound,
    token,
    total_sales_price,
    total_net_profit,
    running_sales_ytd,
    prev_state_sales,
    state_rank
FROM ranked
WHERE state_rank <= 3
ORDER BY d_year DESC, d_month_seq DESC
LIMIT 100
