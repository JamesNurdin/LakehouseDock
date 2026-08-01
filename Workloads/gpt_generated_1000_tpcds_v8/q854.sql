WITH promo_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(\\w+)', 1) AS first_word,
        split(p.p_promo_name, ' ') AS name_parts,
        t.word_count
    FROM promotion p
    CROSS JOIN LATERAL (
        SELECT cardinality(split(p.p_promo_name, ' ')) AS word_count
    ) AS t
    WHERE regexp_like(p.p_promo_name, '^H.*')
),
promo_words AS (
    SELECT
        pf.p_promo_sk,
        pf.p_promo_name,
        w.word
    FROM promo_filtered pf
    CROSS JOIN UNNEST(pf.name_parts) AS w(word)
    WHERE w.word LIKE '%large%'
),
sales_agg AS (
    SELECT
        pw.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_profit) AS avg_profit,
        ROW_NUMBER() OVER (PARTITION BY pw.p_promo_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM promo_words pw
    JOIN web_sales ws ON ws.ws_promo_sk = pw.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY pw.p_promo_sk
),
cust_no_purchase AS (
    SELECT DISTINCT c.c_customer_sk
    FROM customer c
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_sales ss
        JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
        WHERE ss.ss_customer_sk = c.c_customer_sk
          AND d2.d_year = 2002
    )
),
demo_info AS (
    SELECT
        cd.cd_gender,
        cd.cd_education_status,
        COUNT(*) AS cnt
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk IN (SELECT c_customer_sk FROM cust_no_purchase)
    GROUP BY cd.cd_gender, cd.cd_education_status
)
SELECT DISTINCT
    sa.p_promo_sk,
    pf.p_promo_name,
    sa.orders,
    sa.total_profit,
    sa.avg_profit,
    2002 AS sales_year,
    di.cd_gender,
    di.cd_education_status,
    di.cnt,
    ROW_NUMBER() OVER (ORDER BY sa.total_profit DESC) AS global_rank
FROM sales_agg sa
JOIN promo_filtered pf ON sa.p_promo_sk = pf.p_promo_sk
JOIN demo_info di ON TRUE
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_promo_sk = sa.p_promo_sk
      AND cs.cs_sold_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_year = 2003 LIMIT 1)
)
UNION DISTINCT
SELECT
    NULL AS p_promo_sk,
    'No Promotion' AS p_promo_name,
    0 AS orders,
    0.0 AS total_profit,
    0.0 AS avg_profit,
    2002 AS sales_year,
    di.cd_gender,
    di.cd_education_status,
    di.cnt,
    ROW_NUMBER() OVER (ORDER BY 0) AS global_rank
FROM demo_info di
ORDER BY total_profit DESC
LIMIT 100
