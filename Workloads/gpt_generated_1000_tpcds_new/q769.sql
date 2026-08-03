WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_promo_sk,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        d.d_year,
        d.d_week_seq,
        p.p_channel_catalog,
        p.p_channel_email,
        p.p_promo_name,
        c.cc_state,
        c.cc_city,
        c.cc_gmt_offset,
        ARRAY[ c.cc_state, c.cc_city ] AS location_arr
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN call_center c
        ON c.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND p.p_channel_catalog = 'N'
      AND p.p_channel_email = 'Y'
      AND c.cc_gmt_offset BETWEEN -5.00 AND 5.00
      AND ss.ss_ext_sales_price > 1000.00
      AND ss.ss_quantity >= 2
)
SELECT
    b.d_year,
    b.d_week_seq,
    b.cc_state,
    b.cc_city,
    l.location_part,
    SUM(b.ss_ext_sales_price) AS total_sales,
    AVG(b.ss_net_profit) AS avg_profit,
    COUNT(*) AS sales_cnt,
    MIN(b.ss_ext_sales_price) AS min_sales,
    MAX(b.ss_ext_sales_price) AS max_sales,
    CASE WHEN SUM(b.ss_net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_category
FROM base b
CROSS JOIN UNNEST(b.location_arr) AS l (location_part)
WHERE EXISTS (
    SELECT 1
    FROM promotion p_sub
    WHERE p_sub.p_promo_sk = b.ss_promo_sk
      AND p_sub.p_discount_active = 'Y'
)
GROUP BY b.d_year, b.d_week_seq, b.cc_state, b.cc_city, l.location_part
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
