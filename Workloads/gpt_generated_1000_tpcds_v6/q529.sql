WITH base AS (
    SELECT
        d.d_year,
        cp.cp_catalog_page_id,
        ss.ss_net_profit,
        ss.ss_quantity,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_net_paid_inc_ship,
        s.s_country,
        ca.ca_state
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND ca.ca_state = 'CA'
      AND s.s_country = 'United States'
      AND cp.cp_catalog_number IN (15, 16, 18)
      AND ws.ws_net_paid_inc_ship > 1000
)
SELECT
    d_year,
    COUNT(DISTINCT cp_catalog_page_id) AS catalog_page_cnt,
    SUM(ss_net_profit) AS store_total_profit,
    SUM(ws_net_profit) AS web_total_profit,
    SUM(ss_net_profit + ws_net_profit) AS combined_total_profit,
    RANK() OVER (ORDER BY SUM(ss_net_profit + ws_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(ss_quantity) + SUM(ws_quantity) > 10000 THEN 'High Volume'
        WHEN SUM(ss_quantity) + SUM(ws_quantity) > 5000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM base
GROUP BY d_year
ORDER BY combined_total_profit DESC
LIMIT 10
