WITH
store_sales_agg AS (
    SELECT
        s.s_store_sk,
        d.d_date,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS store_sales_rank
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE s.s_closed_date_sk IS NULL
    GROUP BY s.s_store_sk, d.d_date, d.d_year
),
web_sales_agg AS (
    SELECT
        w.web_site_sk,
        d.d_date,
        d.d_year,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY w.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS web_sales_rank
    FROM web_site w
    JOIN web_sales ws ON w.web_site_sk = ws.ws_web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY w.web_site_sk, d.d_date, d.d_year
),
catalog_sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        d.d_date,
        d.d_year,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS catalog_sales_rank
    FROM call_center cc
    JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cc.cc_call_center_sk, d.d_date, d.d_year
),
combined_sales AS (
    SELECT
        COALESCE(ssa.s_store_sk, -1) AS entity_sk,
        CASE
            WHEN ssa.s_store_sk IS NOT NULL THEN 'STORE'
            WHEN wsa.web_site_sk IS NOT NULL THEN 'WEB'
            ELSE 'CATALOG'
        END AS entity_type,
        COALESCE(ssa.d_date, wsa.d_date, csa.d_date, DATE '1970-01-01') AS sales_date,
        COALESCE(ssa.store_net_paid, 0) + COALESCE(wsa.web_net_paid, 0) + COALESCE(csa.catalog_net_paid, 0) AS total_net_paid,
        COALESCE(ssa.store_net_profit, 0) + COALESCE(wsa.web_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0) AS total_net_profit,
        COALESCE(ssa.store_sales_cnt, 0) + COALESCE(wsa.web_sales_cnt, 0) + COALESCE(csa.catalog_sales_cnt, 0) AS total_sales_cnt,
        GREATEST(COALESCE(ssa.store_net_paid, 0), COALESCE(wsa.web_net_paid, 0), COALESCE(csa.catalog_net_paid, 0)) AS max_net_paid,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(ssa.s_store_sk, wsa.web_site_sk, csa.cc_call_center_sk)
            ORDER BY (COALESCE(ssa.store_net_paid, 0) + COALESCE(wsa.web_net_paid, 0) + COALESCE(csa.catalog_net_paid, 0)) DESC
        ) AS overall_rank,
        CONCAT_WS(' - ',
            COALESCE(s.s_store_name, w.web_name, cc.cc_name),
            CAST(COALESCE(ssa.d_year, wsa.d_year, csa.d_year) AS VARCHAR)
        ) AS descriptive_label
    FROM store_sales_agg ssa
    FULL OUTER JOIN web_sales_agg wsa
        ON ssa.d_date = wsa.d_date
       AND ssa.s_store_sk = wsa.web_site_sk
    FULL OUTER JOIN catalog_sales_agg csa
        ON COALESCE(ssa.d_date, wsa.d_date) = csa.d_date
       AND COALESCE(ssa.s_store_sk, wsa.web_site_sk) = csa.cc_call_center_sk
    LEFT JOIN store s ON s.s_store_sk = ssa.s_store_sk
    LEFT JOIN web_site w ON w.web_site_sk = wsa.web_site_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = csa.cc_call_center_sk
    LEFT JOIN date_dim d ON d.d_date = COALESCE(ssa.d_date, wsa.d_date, csa.d_date)
),
customer_overlap AS (
    SELECT
        ss.ss_customer_sk,
        ws.ws_bill_customer_sk AS ws_customer_sk,
        CASE WHEN ss.ss_customer_sk = ws.ws_bill_customer_sk THEN 1 ELSE 0 END AS is_same_customer
    FROM store_sales ss
    JOIN web_sales ws
        ON ss.ss_item_sk = ws.ws_item_sk
       AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
),
common_customers AS (
    SELECT ss_customer_sk
    FROM customer_overlap
    WHERE is_same_customer = 1
    GROUP BY ss_customer_sk
    HAVING COUNT(*) > 1
),
common_items AS (
    SELECT ss_item_sk AS item_sk FROM store_sales
    INTERSECT
    SELECT ws_item_sk FROM web_sales
),
final AS (
    SELECT
        cs.sales_date,
        cs.entity_type,
        cs.total_net_paid,
        cs.total_net_profit,
        cs.total_sales_cnt,
        cs.max_net_paid,
        cs.overall_rank,
        cs.descriptive_label,
        COALESCE(
            (SELECT MAX(cs2.total_net_paid)
             FROM combined_sales cs2
             WHERE cs2.sales_date = cs.sales_date
               AND cs2.entity_type <> cs.entity_type), 0) AS other_entity_max_net_paid,
        CASE
            WHEN cs.total_net_paid > (SELECT AVG(total_net_paid) FROM combined_sales WHERE sales_date = cs.sales_date) THEN 'AboveAvg'
            WHEN cs.total_net_paid < (SELECT AVG(total_net_paid) FROM combined_sales WHERE sales_date = cs.sales_date) THEN 'BelowAvg'
            ELSE 'Avg'
        END AS relative_performance,
        CASE
            WHEN cs.entity_sk IN (SELECT ss_customer_sk FROM common_customers) THEN 'CrossChannelCustomer'
            ELSE 'UniqueCustomer'
        END AS cross_channel_flag,
        CASE
            WHEN STRPOS(cs.descriptive_label, 'NULL') > 0 THEN NULL
            WHEN cs.descriptive_label IS NULL THEN 'MissingLabel'
            ELSE REPLACE(LOWER(cs.descriptive_label), ' ', '_')
        END AS normalized_label,
        CASE
            WHEN cs.total_sales_cnt > 0 THEN cs.total_net_paid / NULLIF(cs.total_sales_cnt, 0)
            ELSE NULL
        END AS avg_net_paid_per_sale,
        REGEXP_REPLACE(cs.descriptive_label, '[^a-z0-9_]', '') AS cleaned_label,
        (SELECT COUNT(*) FROM common_items) AS common_item_total
    FROM combined_sales cs
    WHERE cs.total_net_paid IS NOT NULL
      AND (cs.total_sales_cnt > 0 OR cs.max_net_paid > 0)
      AND cs.sales_date >= DATE '2000-01-01'
      AND cs.entity_type IS NOT NULL
      AND cs.descriptive_label NOT LIKE '%TEST%'
      AND (
          (cs.entity_type = 'STORE' AND cs.total_net_profit > 0)
          OR (cs.entity_type = 'WEB' AND cs.total_net_profit < 0)
          OR (cs.entity_type = 'CATALOG' AND cs.total_net_profit IS NOT NULL)
      )
    ORDER BY cs.sales_date DESC, cs.total_net_paid DESC
)
SELECT *
FROM final
ORDER BY overall_rank
LIMIT 100
