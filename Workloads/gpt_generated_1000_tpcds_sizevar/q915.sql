WITH
sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        CASE
            WHEN SUM(ss.ss_net_paid) > 100000 THEN 'HIGH'
            ELSE 'LOW'
        END AS sales_category,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS first_word_prod
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
      AND i.i_brand LIKE 'B%'
      AND substr(i.i_item_id, 1, 3) = '001'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, d.d_year, regexp_extract(i.i_product_name, '(\\w+)', 1)
),
returns_agg AS (
    SELECT
        cr.cr_item_sk AS i_item_sk,
        i.i_item_id,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        CASE
            WHEN SUM(cr.cr_return_amount) > 50000 THEN 'HIGH_RETURN'
            ELSE 'LOW_RETURN'
        END AS return_category
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand LIKE 'B%'
      AND regexp_like(i.i_item_desc, '.*(size|color).*')
    GROUP BY cr.cr_item_sk, i.i_item_id, d.d_year
),
union_set AS (
    SELECT
        sa.i_item_sk,
        sa.i_item_id,
        sa.i_brand,
        sa.sales_category AS category,
        sa.total_net_paid,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        CASE
            WHEN sa.total_net_paid - COALESCE(ra.total_return_amount, 0) > 50000 THEN 'PROFITABLE'
            ELSE 'MARGINAL'
        END AS profit_status
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.i_item_sk = ra.i_item_sk

    UNION DISTINCT

    SELECT
        ra.i_item_sk,
        ra.i_item_id,
        NULL AS i_brand,
        ra.return_category AS category,
        0 AS total_net_paid,
        ra.total_return_amount,
        CASE
            WHEN ra.total_return_amount > 20000 THEN 'LOSS'
            ELSE 'NEUTRAL'
        END AS profit_status
    FROM returns_agg ra
    WHERE ra.i_item_sk NOT IN (SELECT i_item_sk FROM sales_agg)
),
filtered_set AS (
    SELECT
        u.*,
        lt.full_key,
        lt.id_len
    FROM union_set u
    LEFT JOIN LATERAL (
        SELECT
            concat(u.i_item_id, '-', coalesce(u.i_brand, '')) AS full_key,
            length(u.i_item_id) AS id_len
    ) lt ON true
    WHERE u.category IS NOT NULL
),
exclude_items AS (
    SELECT i_item_sk
    FROM item
    WHERE regexp_like(i_item_desc, '.*Discontinued.*')
),
final_set AS (
    SELECT *
    FROM filtered_set f
    WHERE f.i_item_sk NOT IN (SELECT i_item_sk FROM exclude_items)
      AND f.i_item_sk NOT IN (
          SELECT i_item_sk FROM sales_agg
          EXCEPT
          SELECT i_item_sk FROM returns_agg
      )
)
SELECT
    f.i_item_sk,
    f.i_item_id,
    f.i_brand,
    f.category,
    f.profit_status,
    f.full_key
FROM final_set f
LIMIT 100
