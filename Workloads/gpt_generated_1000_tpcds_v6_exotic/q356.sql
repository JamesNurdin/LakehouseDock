WITH max_date_2001 AS (
    SELECT MAX(d_date) AS max_dt
    FROM date_dim
    WHERE d_year = 2001
)
SELECT source,
       entity_id,
       year,
       total_net_profit
FROM (
    SELECT
        'store' AS source,
        s.s_store_id AS entity_id,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND d.d_date <= (SELECT max_dt FROM max_date_2001)
    GROUP BY s.s_store_id, d.d_year

    UNION ALL

    SELECT
        'call_center' AS source,
        c.cc_call_center_id AS entity_id,
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center c
        ON cs.cs_call_center_sk = c.cc_call_center_sk
    WHERE d.d_year = 2001
      AND d.d_date <= (SELECT max_dt FROM max_date_2001)
    GROUP BY c.cc_call_center_id, d.d_year
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
