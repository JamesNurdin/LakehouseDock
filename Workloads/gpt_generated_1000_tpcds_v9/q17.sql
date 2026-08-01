WITH returns_agg_by_item AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        d.d_year AS year,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cr.cr_item_sk, d.d_year
),
sales_agg_by_store_item AS (
    SELECT
        s.s_store_name,
        s.s_city,
        d.d_year,
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE s.s_store_name LIKE 'Store%'
      AND REGEXP_LIKE(i.i_item_desc, '.*[0-9]{4}.*')
      AND d.d_year = 2002
    GROUP BY s.s_store_name, s.s_city, d.d_year, ss.ss_item_sk
)
SELECT
    s_agg.s_store_name,
    concat(s_agg.s_store_name, ' - ', s_agg.s_city) AS store_full_name,
    s_agg.d_year,
    REGEXP_EXTRACT(i.i_item_id, '\\d+', 0) AS item_number,
    s_agg.total_net_paid,
    COALESCE(r_agg.total_net_loss, 0) AS total_net_loss
FROM sales_agg_by_store_item s_agg
JOIN item i ON s_agg.item_sk = i.i_item_sk
LEFT JOIN returns_agg_by_item r_agg
    ON s_agg.item_sk = r_agg.item_sk
    AND s_agg.d_year = r_agg.year
ORDER BY s_agg.total_net_paid DESC
LIMIT 100
