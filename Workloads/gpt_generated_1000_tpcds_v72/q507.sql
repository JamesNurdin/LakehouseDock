WITH catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        REGEXP_EXTRACT(i.i_product_name, '^([^ ]+)', 1) AS first_word_product
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE REGEXP_LIKE(cp.cp_description, '(?i)urban')
      AND p.p_channel_details LIKE '%marketing%'
    GROUP BY d.d_year, d.d_month_seq, REGEXP_EXTRACT(i.i_product_name, '^([^ ]+)', 1)
)
SELECT
    ca.d_year,
    ca.d_month_seq,
    ca.catalog_net_profit,
    ca.distinct_items,
    ca.first_word_product,
    (
        SELECT SUM(ss.ss_net_paid)
        FROM store_sales ss
        JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = ca.d_year
          AND d2.d_month_seq = ca.d_month_seq
    ) AS store_total_paid
FROM catalog_agg ca
ORDER BY ca.d_year, ca.d_month_seq DESC
LIMIT 100
