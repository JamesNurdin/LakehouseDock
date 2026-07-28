WITH sales_union AS (
    SELECT
        'catalog' AS channel,
        i.i_item_id,
        d.d_year AS sales_year,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_brand = 'Brand#23'
      AND d.d_year = 2001
      AND p.p_channel_dmail = 'Y'
    GROUP BY i.i_item_id, d.d_year

    UNION ALL

    SELECT
        'store' AS channel,
        i.i_item_id,
        d.d_year AS sales_year,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE i.i_brand = 'Brand#23'
      AND d.d_year = 2001
      AND p.p_channel_dmail = 'Y'
    GROUP BY i.i_item_id, d.d_year
)
SELECT
    channel,
    i_item_id,
    sales_year,
    total_net_paid
FROM sales_union
ORDER BY total_net_paid DESC
