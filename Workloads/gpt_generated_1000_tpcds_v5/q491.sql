WITH cs_agg AS (
        SELECT
            d.d_year,
            SUM(cs.cs_net_profit) AS catalog_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE cs.cs_ext_ship_cost > 500
          AND hd.hd_vehicle_count >= 2
          AND d.d_year BETWEEN 2000 AND 2002
        GROUP BY d.d_year
    ),
    ss_agg AS (
        SELECT
            d.d_year,
            s.s_store_sk,
            s.s_store_name,
            s.s_state,
            SUM(ss.ss_net_profit) AS store_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE s.s_state = 'CA'
        GROUP BY d.d_year, s.s_store_sk, s.s_store_name, s.s_state
    ),
    ws_agg AS (
        SELECT
            d.d_year,
            ws.web_site_sk,
            ws.web_name
        FROM web_site ws
        JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
        WHERE ws.web_tax_percentage < 5
        GROUP BY d.d_year, ws.web_site_sk, ws.web_name
    )
SELECT
    ss.s_store_name,
    cs.d_year,
    cs.catalog_profit,
    ss.store_profit,
    (cs.catalog_profit + ss.store_profit) AS total_profit,
    CASE
        WHEN (cs.catalog_profit + ss.store_profit) >= 50000 THEN 'High'
        WHEN (cs.catalog_profit + ss.store_profit) >= 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    ws.web_name,
    RANK() OVER (PARTITION BY cs.d_year ORDER BY (cs.catalog_profit + ss.store_profit) DESC) AS profit_rank
FROM ss_agg ss
JOIN cs_agg cs ON cs.d_year = ss.d_year
JOIN ws_agg ws ON ws.d_year = cs.d_year
WHERE EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim d2 ON wp.wp_creation_date_sk = d2.d_date_sk
        WHERE d2.d_year = cs.d_year
          AND wp.wp_type = 'product'
    )
GROUP BY ss.s_store_name, cs.d_year, cs.catalog_profit, ss.store_profit, ws.web_name
HAVING (cs.catalog_profit + ss.store_profit) > 10000
ORDER BY total_profit DESC
LIMIT 100
