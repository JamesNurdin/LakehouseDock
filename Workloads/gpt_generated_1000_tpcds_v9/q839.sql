/* goal: Identify top customers in year 2000 with high profit from catalog sales, enriched with return and web sales information, rank them by profit, and flag customers that also have any web‑sales activity. */
WITH sales_agg AS (
   SELECT
       c.c_customer_sk,
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       d.d_year,
       SUM(cs.cs_ext_sales_price)               AS total_sales,
       SUM(cs.cs_net_profit)                    AS total_profit,
       COUNT(DISTINCT cs.cs_promo_sk)           AS promo_count,
       SUM(COALESCE(sr.sr_return_amt, 0))       AS total_returns,
       SUM(COALESCE(ws.ws_ext_sales_price, 0))  AS total_web_sales
   FROM catalog_sales cs
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer c
     ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
     ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN store_returns sr
     ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
   LEFT JOIN web_sales ws
     ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_page wp
     ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2000
     AND p.p_channel_dmail = 'Y'
     AND cs.cs_quantity >= 5
     AND ca.ca_country = 'United States'
   GROUP BY
     c.c_customer_sk,
     c.c_customer_id,
     c.c_first_name,
     c.c_last_name,
     d.d_year
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    total_sales,
    total_profit,
    promo_count,
    total_returns,
    total_web_sales,
    CASE
        WHEN total_profit > 50000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year,
    (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS overall_avg_sales_price,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = c_customer_sk
        ) THEN 1
        ELSE 0
    END AS has_web_sales_flag
FROM sales_agg
ORDER BY total_profit DESC
LIMIT 100
