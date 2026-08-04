WITH ws_dim AS (
   SELECT
       ws.ws_bill_customer_sk AS customer_sk,
       ws.ws_net_paid AS net_paid,
       ws.ws_quantity AS quantity,
       ws.ws_sold_date_sk AS sold_date_sk,
       ws.ws_web_page_sk,
       ws.ws_web_site_sk
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE wsite.web_state = 'CA'
     AND ib.ib_lower_bound >= 150000
     AND wp.wp_type = 'content'
),
ws_agg AS (
   SELECT
       customer_sk,
       SUM(net_paid) AS ws_total_paid,
       SUM(quantity) AS ws_total_qty
   FROM ws_dim
   WHERE quantity < 10
   GROUP BY customer_sk
),
ss_dim AS (
   SELECT
       ss.ss_customer_sk AS customer_sk,
       ss.ss_net_paid AS net_paid,
       ss.ss_quantity AS quantity,
       ss.ss_sold_date_sk AS sold_date_sk,
       ss.ss_item_sk
   FROM store_sales ss
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ss.ss_quantity > 5
     AND ib.ib_upper_bound <= 200000
),
ss_agg AS (
   SELECT
       customer_sk,
       SUM(net_paid) AS ss_total_paid,
       SUM(quantity) AS ss_total_qty
   FROM ss_dim
   GROUP BY customer_sk
),
cust_intersect AS (
   SELECT customer_sk FROM ws_agg
   INTERSECT
   SELECT customer_sk FROM ss_agg
),
combined AS (
   SELECT
       ci.customer_sk,
       ws.ws_total_paid,
       ss.ss_total_paid,
       ws.ws_total_qty,
       ss.ss_total_qty,
       (ws.ws_total_paid + ss.ss_total_paid) AS total_amount
   FROM cust_intersect ci
   JOIN ws_agg ws ON ci.customer_sk = ws.customer_sk
   JOIN ss_agg ss ON ci.customer_sk = ss.customer_sk
   WHERE NOT EXISTS (
       SELECT 1 FROM catalog_returns cr
       WHERE cr.cr_refunded_customer_sk = ci.customer_sk
   )
),
unnested AS (
   SELECT
       c.customer_sk,
       amt_type,
       amount
   FROM combined c
   CROSS JOIN UNNEST(
       ARRAY[ c.ws_total_paid, c.ss_total_paid ],
       ARRAY[ 'web', 'store' ]
   ) AS t (amount, amt_type)
)
SELECT
   customer_sk,
   amt_type,
   amount
FROM unnested
ORDER BY amount DESC
OFFSET 10 ROWS
LIMIT 100
