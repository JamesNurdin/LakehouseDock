WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_formulation,
        SUM(ss.ss_ext_sales_price)        AS total_sales,
        SUM(ss.ss_net_profit)              AS total_profit
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)goldenrod')
      AND i.i_item_desc LIKE '%goldenrod%'
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_formulation
)
SELECT
    sa.i_item_sk,
    sa.i_item_desc,
    regexp_extract(sa.i_formulation, '(\\d+)')            AS formulation_number,
    sa.total_sales,
    sa.total_profit,
    RANK() OVER (ORDER BY sa.total_profit DESC)           AS profit_rank,
    p.p_promo_name,
    CONCAT('Promo-', p.p_promo_id)                        AS promo_label
FROM sales_agg sa
JOIN promotion p
    ON p.p_item_sk = sa.i_item_sk
WHERE p.p_channel_tv = 'Y'
  AND (p.p_channel_email = 'N' OR p.p_channel_email IS NULL)
ORDER BY profit_rank
LIMIT 100
