WITH store_sales_full AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_product_name,
        i.i_color,
        i.i_brand,
        p.p_promo_name,
        d.d_date,
        d.d_day_name,
        d.d_current_day,
        -- string processing on product name
        regexp_extract(i.i_product_name, '\\d{3}', 0) AS product_code,
        CASE
            WHEN regexp_like(i.i_product_name, '.*[A-Z]{2}.*') THEN 'Contains2Upper'
            ELSE 'No2Upper'
        END AS prod_name_upper_flag,
        substr(s.s_store_name, 1, 5) AS store_name_prefix,
        concat(s.s_store_name, ' - ', COALESCE(p.p_promo_name, 'NoPromo')) AS store_promo_label
    FROM store s
    FULL OUTER JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = ss.ss_item_sk
          AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
    )
),

store_keys AS (
    SELECT s.s_store_sk AS store_sk
    FROM store s
    WHERE s.s_state LIKE 'C%'
),

sales_keys AS (
    SELECT ss.ss_store_sk AS store_sk
    FROM store_sales ss
    WHERE ss.ss_net_profit > 0
),

store_sales_intersect AS (
    SELECT store_sk FROM store_keys
    INTERSECT
    SELECT store_sk FROM sales_keys
),

store_profit_rank AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank_state
    FROM store s
    JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state
),

final_agg AS (
    SELECT
        ssf.s_state,
        ssf.i_brand,
        COUNT(DISTINCT ssf.ss_item_sk) AS distinct_items_sold,
        SUM(ssf.ss_net_profit) AS total_profit,
        GROUPING(ssf.s_state) AS grp_state,
        GROUPING(ssf.i_brand) AS grp_brand
    FROM store_sales_full ssf
    GROUP BY GROUPING SETS (
        (ssf.s_state, ssf.i_brand),
        (ssf.s_state),
        (ssf.i_brand),
        ()
    )
)

SELECT
    f.s_state,
    f.i_brand,
    f.distinct_items_sold,
    f.total_profit,
    CASE
        WHEN f.grp_state = 1 AND f.grp_brand = 0 THEN 'All Brands, per State'
        WHEN f.grp_state = 0 AND f.grp_brand = 1 THEN 'All States, per Brand'
        WHEN f.grp_state = 1 AND f.grp_brand = 1 THEN 'Grand Total'
        ELSE 'State & Brand Detail'
    END AS grouping_level,
    r.profit_rank_state,
    r.total_net_profit,
    fs.store_promo_label
FROM final_agg f
LEFT JOIN store_profit_rank r
    ON f.s_state = r.s_state
LEFT JOIN store_sales_full fs
    ON r.s_store_sk = fs.s_store_sk
WHERE r.s_store_sk IN (SELECT store_sk FROM store_sales_intersect)
ORDER BY f.total_profit DESC, f.s_state
LIMIT 100
