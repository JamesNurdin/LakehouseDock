-- goal: Compare total net sales and order counts across store and web channels by year and month, 
-- including subtotals, using a UNION ALL of two aggregated CTEs. The store and web rows are filtered to
-- only those items that also appear in catalog_sales for the same year (checked with an EXISTS subquery).
-- Results are ordered by year, month and channel and limited to the top 100 rows.

WITH
store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name AS entity,
        'store' AS channel,
        SUM(ss.ss_net_paid)      AS total_sales,
        COUNT(*)                 AS order_count
    FROM store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s         ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p     ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          JOIN item i          ON cs.cs_item_sk = i.i_item_sk
          JOIN date_dim cd     ON cs.cs_sold_date_sk = cd.d_date_sk
          WHERE cd.d_year = d.d_year
            AND i.i_item_sk = ss.ss_item_sk
      )
    GROUP BY GROUPING SETS (
        (d.d_year, d.d_month_seq, s.s_store_name),
        (d.d_year, d.d_month_seq),
        (d.d_year),
        ()
    )
),

web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wp.wp_type AS entity,
        'web' AS channel,
        SUM(ws.ws_net_paid)      AS total_sales,
        COUNT(*)                 AS order_count
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp     ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN promotion p     ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs
          JOIN item i          ON cs.cs_item_sk = i.i_item_sk
          JOIN date_dim cd     ON cs.cs_sold_date_sk = cd.d_date_sk
          WHERE cd.d_year = d.d_year
            AND i.i_item_sk = ws.ws_item_sk
      )
    GROUP BY GROUPING SETS (
        (d.d_year, d.d_month_seq, wp.wp_type),
        (d.d_year, d.d_month_seq),
        (d.d_year),
        ()
    )
)

SELECT
    channel,
    d_year,
    d_month_seq,
    entity,
    total_sales,
    order_count
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) AS combined
ORDER BY d_year DESC, d_month_seq DESC, channel
LIMIT 100
