WITH sales_agg AS (
   SELECT
       s.s_store_id,
       td.t_hour,
       ss.ss_ticket_number,
       ss.ss_quantity,
       ss.ss_sales_price,
       ss.ss_net_paid,
       ss.ss_net_profit,
       c.c_customer_id,
       ca.ca_state,
       p.p_discount_active,
       r.r_reason_desc,
       sr.sr_return_amt,
       ws.ws_sales_price AS web_sales_price,
       -- correlated scalar subquery: total catalog sales amount for this customer & order
       (SELECT SUM(cs.cs_ext_sales_price)
        FROM catalog_sales cs
        WHERE cs.cs_bill_customer_sk = c.c_customer_sk
          AND cs.cs_order_number = ss.ss_ticket_number) AS cust_catalog_sales,
       -- window function: previous net paid for the same store (ordered by time key)
       LAG(ss.ss_net_paid) OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_sold_time_sk) AS prev_net_paid,
       -- array that will later be unnested
       ARRAY[ss.ss_quantity, CAST(ss.ss_sales_price AS double)] AS qty_price_arr
   FROM store_sales ss
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_store_sk = s.s_store_sk
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                           AND ws.ws_sold_time_sk = td.t_time_sk
   -- LATERAL join to fetch the promo name (correlated)
   CROSS JOIN LATERAL (
        SELECT p2.p_promo_name
        FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk
        LIMIT 1
   ) AS promo_lat (promo_name)
   WHERE
       ss.ss_quantity > 2
       AND ss.ss_sales_price > 50
       AND p.p_discount_active = 'Y'
       AND ca.ca_state = 'CA'
       AND td.t_hour BETWEEN 9 AND 17
       AND (sr.sr_return_amt IS NULL OR sr.sr_return_amt < 100)
),
expanded AS (
   SELECT
       s_store_id,
       t_hour,
       ss_ticket_number,
       c_customer_id,
       ca_state,
       p_discount_active,
       r_reason_desc,
       sr_return_amt,
       web_sales_price,
       cust_catalog_sales,
       prev_net_paid,
       val,
       idx
   FROM sales_agg
   CROSS JOIN UNNEST(qty_price_arr) WITH ORDINALITY AS u(val, idx)
)
SELECT
    s_store_id,
    t_hour,
    SUM(CASE WHEN idx = 1 THEN val END) AS total_quantity,
    SUM(CASE WHEN idx = 2 THEN val END) AS total_sales_price,
    SUM(cust_catalog_sales) AS total_cust_catalog_sales,
    AVG(prev_net_paid) AS avg_prev_net_paid,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(sr_return_amt) AS total_return_amount,
    r_reason_desc,
    SUM(web_sales_price) AS total_web_sales_price
FROM expanded
GROUP BY
    s_store_id,
    t_hour,
    r_reason_desc
ORDER BY
    total_cust_catalog_sales DESC
LIMIT 100
