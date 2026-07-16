WITH date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2002
),
catalog_agg AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_call_center_sk AS cc_sk,
           SUM(cs.cs_net_profit) AS profit,
           COUNT(*) AS orders,
           MAX(cs.cs_sold_date_sk) AS latest_sold_date_sk
    FROM catalog_sales cs
    JOIN date_filter df ON cs.cs_sold_date_sk = df.d_date_sk
    GROUP BY cs.cs_bill_customer_sk, cs.cs_call_center_sk
),
store_agg AS (
    SELECT ss.ss_customer_sk AS cust_sk,
           NULL AS cc_sk,
           SUM(ss.ss_net_profit) AS profit,
           COUNT(*) AS orders,
           MAX(ss.ss_sold_date_sk) AS latest_sold_date_sk
    FROM store_sales ss
    JOIN date_filter df ON ss.ss_sold_date_sk = df.d_date_sk
    GROUP BY ss.ss_customer_sk
),
cust_in_both AS (
    SELECT cust_sk FROM catalog_agg
    INTERSECT
    SELECT cust_sk FROM store_agg
),
combined AS (
    SELECT cust_sk, cc_sk, profit, orders, latest_sold_date_sk, 'Catalog' AS source
    FROM catalog_agg
    UNION ALL
    SELECT cust_sk, cc_sk, profit, orders, latest_sold_date_sk, 'Store' AS source
    FROM store_agg
),
customer_info AS (
    SELECT c.c_customer_sk AS cust_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(cd.cd_gender, 'U') AS gender,
           COALESCE(cd.cd_education_status, 'Unknown') AS education,
           COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
call_center_info AS (
    SELECT cc.cc_call_center_sk,
           cc.cc_name,
           cc.cc_manager,
           cc.cc_gmt_offset,
           cc.cc_tax_percentage
    FROM call_center cc
),
final AS (
    SELECT
        cmb.cust_sk,
        ci.full_name,
        ci.gender,
        ci.education,
        ci.pref_flag,
        COALESCE(cci.cc_name, 'No Call Center') AS call_center_name,
        COALESCE(cci.cc_manager, 'N/A') AS call_center_manager,
        COALESCE(cci.cc_gmt_offset, 0) AS call_center_gmt_offset,
        COALESCE(cci.cc_tax_percentage, 0) AS call_center_tax_pct,
        cmb.profit,
        cmb.orders,
        cmb.source,
        d.d_date,
        CASE WHEN cmb.orders = 0 THEN 0 ELSE cmb.profit / cmb.orders END AS profit_per_order,
        CASE
            WHEN cmb.profit > 100000 THEN 'High'
            WHEN cmb.profit > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY cmb.source ORDER BY cmb.profit DESC) AS rank_in_source,
        ROW_NUMBER() OVER (ORDER BY cmb.profit DESC) AS overall_rank,
        (SELECT AVG(c2.profit)
         FROM combined c2
         JOIN customer_info ci2 ON c2.cust_sk = ci2.cust_sk
         WHERE c2.source = cmb.source
           AND ci2.gender = ci.gender) AS avg_profit_same_gender_source,
        date_diff('day', d.d_date, DATE '2024-10-01') AS days_since_last_sale,
        CASE WHEN regexp_like(ci.full_name, '[AEIOUaeiou]') THEN 'ContainsVowel' ELSE 'NoVowel' END AS vowel_flag,
        COALESCE(NULLIF(ci.pref_flag, ''), 'N') AS normalized_pref_flag,
        cmb.profit * (1 + COALESCE(cci.cc_tax_percentage, 0) / 100) AS adjusted_profit
    FROM combined cmb
    JOIN customer_info ci ON cmb.cust_sk = ci.cust_sk
    LEFT JOIN call_center_info cci ON cmb.cc_sk = cci.cc_call_center_sk
    LEFT JOIN date_dim d ON cmb.latest_sold_date_sk = d.d_date_sk
    WHERE cmb.profit IS NOT NULL
      AND EXISTS (SELECT 1 FROM cust_in_both cib WHERE cib.cust_sk = cmb.cust_sk)
)
SELECT *
FROM final
WHERE overall_rank <= 20
ORDER BY overall_rank
