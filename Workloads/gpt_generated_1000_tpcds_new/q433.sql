WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_promo_sk,
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        d.d_year,
        i.i_color,
        i.i_brand,
        p.p_discount_active,
        s.s_state
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_color = 'lime'
      AND s.s_state = 'CA'
      AND d.d_year = 2001
      AND p.p_discount_active = 'Y'
),

catalog_cte AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        d2.d_year AS cp_year
    FROM catalog_page cp
    JOIN date_dim d2 ON cp.cp_start_date_sk = d2.d_date_sk
    WHERE cp.cp_department = 'Electronics'
      AND d2.d_year = 2001
),

web_cte AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_customer_sk,
        d3.d_year AS wp_year
    FROM web_page wp
    JOIN date_dim d3 ON wp.wp_creation_date_sk = d3.d_date_sk
    WHERE wp.wp_type = 'article'
      AND d3.d_year = 2001
),

union_set AS (
    SELECT s.s_store_sk AS key_id
    FROM sales_base sb
    JOIN store s ON sb.ss_store_sk = s.s_store_sk
    UNION
    SELECT cp.cp_catalog_page_sk AS key_id
    FROM catalog_cte cp
),

intersect_set AS (
    SELECT key_id FROM union_set
    INTERSECT
    SELECT wp.wp_web_page_sk AS key_id FROM web_cte wp
)
SELECT
    d.d_year,
    i.i_color,
    COUNT(DISTINCT sb.ss_ticket_number) AS distinct_tickets,
    SUM(sb.ss_ext_sales_price) AS total_sales,
    AVG(sb.ss_net_profit) AS avg_profit,
    MIN(sb.ss_quantity) AS min_qty,
    MAX(sb.ss_quantity) AS max_qty,
    CASE WHEN SUM(sb.ss_ext_sales_price) > 1000000 THEN 'HIGH' ELSE 'LOW' END AS sales_volume_category,
    ic.wp_cnt
FROM sales_base sb
JOIN date_dim d ON sb.ss_sold_date_sk = d.d_date_sk
JOIN item i ON sb.ss_item_sk = i.i_item_sk
FULL OUTER JOIN catalog_cte cp ON sb.ss_store_sk = cp.cp_catalog_page_sk
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS wp_cnt
    FROM web_page wp
    WHERE wp.wp_customer_sk = sb.ss_customer_sk
) ic ON TRUE
WHERE EXISTS (
    SELECT 1 FROM intersect_set iset WHERE iset.key_id = sb.ss_store_sk
)
GROUP BY d.d_year, i.i_color, ic.wp_cnt
ORDER BY total_sales DESC
LIMIT 100
