WITH date_filtered AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
),
store_filtered AS (
    SELECT *
    FROM store
    WHERE s_state = 'CA'
      AND s_store_sk IN (SELECT s_store_sk FROM store WHERE s_city = 'Seattle')
),
call_center_filtered AS (
    SELECT *
    FROM call_center
    WHERE cc_market_manager LIKE '%Smith%'
),
catalog_page_filtered AS (
    SELECT *
    FROM catalog_page
    WHERE cp_department = 'Sports'
),
-- central fact table (catalog_sales) filtered and joined to the dimension tables that have direct join rules
fact AS (
    SELECT cs.*
    FROM catalog_sales cs
    JOIN date_filtered d          ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center_filtered cc   ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page_filtered cp  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_quantity > 0
),
-- join every other selected table directly to the central fact (star schema)
joined AS (
    SELECT
        d.d_year,
        s.s_store_name,
        cc.cc_name,
        cp.cp_department,
        cf.cs_item_sk,
        cf.cs_net_profit,
        ss.ss_customer_sk,
        g.grp
    FROM fact cf
    JOIN date_dim d               ON d.d_date_sk = cf.cs_sold_date_sk
    JOIN time_dim t               ON t.t_time_sk = cf.cs_sold_time_sk
    JOIN store_sales ss           ON ss.ss_sold_date_sk = cf.cs_sold_date_sk
    JOIN store s                  ON s.s_store_sk = ss.ss_store_sk
    JOIN call_center cc           ON cc.cc_call_center_sk = cf.cs_call_center_sk
    JOIN catalog_page cp          ON cp.cp_catalog_page_sk = cf.cs_catalog_page_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cf.cs_order_number
                                 AND cr.cr_item_sk = cf.cs_item_sk
    LEFT JOIN inventory inv      ON inv.inv_date_sk = d.d_date_sk
    CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) g
    WHERE cf.cs_call_center_sk IN (
            SELECT cc_call_center_sk FROM call_center
            INTERSECT
            SELECT cs_call_center_sk FROM catalog_sales WHERE cs_quantity > 5
          )
      AND cf.cs_catalog_page_sk IN (
            SELECT cp_catalog_page_sk FROM catalog_page WHERE cp_type = 'A'
          )
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND t.t_hour BETWEEN 9 AND 17
),
-- aggregation with distinct counts
aggregated AS (
    SELECT
        d_year,
        s_store_name,
        cc_name,
        cp_department,
        COUNT(DISTINCT cs_item_sk)          AS distinct_items_sold,
        COUNT(DISTINCT ss_customer_sk)      AS distinct_store_customers,
        SUM(cs_net_profit)                  AS total_profit,
        grp
    FROM joined
    GROUP BY d_year, s_store_name, cc_name, cp_department, grp
    HAVING SUM(cs_net_profit) > 0
),
-- rank rows within each store and keep top‑5 per store
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_profit DESC) AS rn
    FROM aggregated
)
SELECT
    d_year,
    s_store_name,
    cc_name,
    cp_department,
    distinct_items_sold,
    distinct_store_customers,
    total_profit
FROM ranked
WHERE rn <= 5
ORDER BY total_profit DESC
LIMIT 100
