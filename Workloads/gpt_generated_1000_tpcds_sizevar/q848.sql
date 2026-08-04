WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),

sales_enriched AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        s.s_store_name,
        s.s_city,
        d_sales.d_year        AS sales_year,
        p.p_promo_name,
        d_promo_start.d_year AS promo_start_year,
        cp.cp_department,
        cp.cp_catalog_page_number,
        wp.wp_image_count,
        cc.cc_name            AS call_center_name,
        r.r_reason_desc,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM sampled_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    -- reuse promotion table under a different alias to obtain start‑date information
    JOIN promotion pd
        ON p.p_promo_sk = pd.p_promo_sk
    JOIN date_dim d_promo_start
        ON pd.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_store_sk = sr.sr_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON ss.ss_item_sk = cs.cs_item_sk
       AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_page wp
        ON cp.cp_start_date_sk = wp.wp_creation_date_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
),

intersect_store_ids AS (
    SELECT ss_store_sk FROM sales_enriched
    INTERSECT
    SELECT sr_store_sk FROM store_returns
),

union_metrics AS (
    SELECT ss_store_sk AS store_sk,
           SUM(ss_net_paid) AS metric,
           'sales' AS source
    FROM sales_enriched
    GROUP BY ss_store_sk
    UNION
    SELECT sr_store_sk AS store_sk,
           SUM(sr_net_loss) AS metric,
           'returns' AS source
    FROM store_returns
    GROUP BY sr_store_sk
)
SELECT
    s.s_store_name,
    s.s_city,
    um.store_sk,
    um.source,
    um.metric,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY um.metric DESC) AS store_rank
FROM union_metrics um
JOIN store s
    ON um.store_sk = s.s_store_sk
WHERE um.store_sk IN (SELECT ss_store_sk FROM intersect_store_ids)
GROUP BY s.s_store_name, s.s_city, um.store_sk, um.source, um.metric
HAVING SUM(um.metric) > 1000
ORDER BY um.metric DESC
LIMIT 100
