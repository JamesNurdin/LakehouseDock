WITH catalog_agg AS (
    SELECT cs_sold_date_sk AS date_sk,
           SUM(cs_net_paid) AS catalog_net_paid,
           SUM(cs_net_profit) AS catalog_net_profit
    FROM catalog_sales
    GROUP BY cs_sold_date_sk
), store_agg AS (
    SELECT ss_sold_date_sk AS date_sk,
           SUM(ss_net_paid) AS store_net_paid,
           SUM(ss_net_profit) AS store_net_profit
    FROM store_sales
    GROUP BY ss_sold_date_sk
), web_agg AS (
    SELECT ws_sold_date_sk AS date_sk,
           SUM(ws_net_paid) AS web_net_paid,
           SUM(ws_net_profit) AS web_net_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk
)
SELECT d.d_year,
       d.d_month_seq,
       COALESCE(c.catalog_net_paid, 0) AS catalog_net_paid,
       COALESCE(s.store_net_paid, 0) AS store_net_paid,
       COALESCE(w.web_net_paid, 0) AS web_net_paid,
       COALESCE(c.catalog_net_profit, 0) + COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit
FROM date_dim d
LEFT JOIN catalog_agg c ON d.d_date_sk = c.date_sk
LEFT JOIN store_agg s ON d.d_date_sk = s.date_sk
LEFT JOIN web_agg w ON d.d_date_sk = w.date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
ORDER BY d.d_year, d.d_month_seq
