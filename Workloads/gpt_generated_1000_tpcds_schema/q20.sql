WITH sales_filtered AS (
   SELECT
       ws.ws_sold_date_sk,
       ws.ws_bill_customer_sk AS c_customer_sk,
       ws.ws_net_profit,
       ws.ws_net_paid,
       c.c_first_name,
       c.c_last_name,
       c.c_email_address,
       p.p_promo_name,
       d.d_year,
       r.r_reason_desc
   FROM web_sales ws
   JOIN customer c
     ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN date_dim d
     ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p
     ON ws.ws_promo_sk = p.p_promo_sk
   LEFT JOIN web_returns wr
     ON ws.ws_order_number = wr.wr_order_number
   LEFT JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   WHERE regexp_like(c.c_email_address, '^.+@example\\.com$')
     AND p.p_channel_email = 'N'
     AND (r.r_reason_desc IS NULL OR regexp_like(r.r_reason_desc, 'color'))
),
agg AS (
   SELECT
       d_year,
       c_customer_sk,
       concat(c_first_name, ' ', c_last_name) AS full_name,
       regexp_extract(c_email_address, '@(.+)$', 1) AS email_domain,
       sum(ws_net_profit) AS total_profit,
       sum(ws_net_paid) AS total_paid,
       count(*) AS orders_count
   FROM sales_filtered
   GROUP BY d_year, c_customer_sk, c_first_name, c_last_name, c_email_address
),
ranked AS (
   SELECT
       d_year,
       full_name,
       email_domain,
       total_profit,
       total_paid,
       orders_count,
       row_number() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rnk
   FROM agg
)
SELECT
   d_year,
   full_name,
   email_domain,
   total_profit,
   total_paid,
   orders_count
FROM ranked
WHERE rnk <= 5
ORDER BY d_year ASC, total_profit DESC
LIMIT 100
