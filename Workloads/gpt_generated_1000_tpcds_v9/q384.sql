WITH combined_sales AS (
    SELECT
        i.i_item_id,
        i.i_item_sk AS item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        t.t_shift,
        t.t_sub_shift,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        p.p_channel_details
    FROM store_sales ss
    INNER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
        REGEXP_LIKE(p.p_channel_details, '(churches|church|old|local)')
        AND p.p_discount_active = 'Y'
        AND i.i_product_name LIKE '%Deluxe%'
        AND t.t_sub_shift LIKE 'morning%'
    GROUP BY
        i.i_item_id,
        i.i_item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        t.t_shift,
        t.t_sub_shift,
        p.p_channel_details

    UNION ALL

    SELECT
        i.i_item_id,
        i.i_item_sk AS item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        t.t_shift,
        t.t_sub_shift,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        NULL AS p_channel_details
    FROM store_sales ss
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE
        p.p_promo_sk IS NULL
        AND i.i_product_name LIKE '%Deluxe%'
        AND t.t_sub_shift LIKE 'morning%'
    GROUP BY
        i.i_item_id,
        i.i_item_sk,
        i.i_brand,
        i.i_product_name,
        i.i_item_desc,
        t.t_shift,
        t.t_sub_shift
)
SELECT
    combined.i_item_id,
    combined.item_sk,
    CONCAT(combined.i_brand, ' - ', combined.i_product_name) AS product_label,
    combined.t_shift,
    combined.t_sub_shift,
    combined.total_net_paid,
    combined.total_net_profit,
    combined.sales_cnt,
    combined.avg_discount,
    (
        SELECT AVG(ss2.ss_ext_discount_amt)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = combined.item_sk
    ) AS avg_item_discount,
    CASE WHEN combined.total_net_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
    COALESCE(REGEXP_EXTRACT(combined.p_channel_details, '(churches?|old|local)'), 'N/A') AS channel_keyword,
    SUM(combined.total_net_paid) OVER (PARTITION BY combined.t_shift) AS shift_total_net_paid,
    SUBSTRING(combined.i_item_desc FROM 1 FOR 30) AS item_desc_snippet,
    ROW_NUMBER() OVER (PARTITION BY combined.t_shift ORDER BY combined.total_net_paid DESC) AS rn_shift
FROM combined_sales combined
WHERE combined.total_net_paid > (
    SELECT AVG(promo_totals.total_net_paid)
    FROM (
        SELECT SUM(ss2.ss_net_paid) AS total_net_paid
        FROM store_sales ss2
        INNER JOIN promotion p2 ON ss2.ss_promo_sk = p2.p_promo_sk
        WHERE p2.p_discount_active = 'Y'
        GROUP BY ss2.ss_item_sk
    ) promo_totals
)
ORDER BY
    combined.total_net_profit DESC,
    profit_flag,
    rn_shift
LIMIT 100
