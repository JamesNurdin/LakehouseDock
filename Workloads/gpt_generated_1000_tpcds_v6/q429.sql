/*
goal: Compare yearly sales and profit from store and web channels for 1998‑1999, broken down by promotion email channel, and show subtotals using grouping sets.
*/
WITH store_sales_data AS (
    SELECT DISTINCT
        d.d_year AS year,
        p.p_channel_email AS channel,
        ss.ss_ext_sales_price AS sales,
        ss.ss_net_profit AS profit,
        (
            SELECT avg(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_channel_email = p.p_channel_email
        ) AS avg_promo_cost
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year IN (1998, 1999)
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_store_sk = s.s_store_sk
      )
),
web_sales_data AS (
    SELECT DISTINCT
        d.d_year AS year,
        p.p_channel_email AS channel,
        ws.ws_ext_sales_price AS sales,
        ws.ws_net_profit AS profit,
        (
            SELECT avg(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_channel_email = p.p_channel_email
        ) AS avg_promo_cost
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year IN (1998, 1999)
      AND w.web_city = 'Seattle'
)
SELECT
    year,
    channel,
    sum(sales)        AS total_sales,
    sum(profit)       AS total_profit,
    avg(avg_promo_cost) AS avg_promo_cost
FROM (
    SELECT year, channel, sales, profit, avg_promo_cost FROM store_sales_data
    UNION ALL
    SELECT year, channel, sales, profit, avg_promo_cost FROM web_sales_data
) combined
GROUP BY GROUPING SETS ( (year, channel), (year), () )
ORDER BY year NULLS LAST, channel
LIMIT 100
