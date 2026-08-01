WITH premium_items AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1998-01-01'
      AND d.d_date <= DATE '1998-12-31'
      AND regexp_like(i.i_item_desc, 'Premium.*[0-9]{3}')
),
store_totals AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_division_name,
        s.s_city,
        SUM(pi.ss_net_profit) AS total_net_profit,
        SUM(pi.ss_quantity) AS total_quantity,
        COUNT(DISTINCT pi.ss_item_sk) AS distinct_premium_items
    FROM premium_items pi
    JOIN store s ON pi.ss_store_sk = s.s_store_sk
    WHERE s.s_store_name LIKE '%Store%'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
          JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
          WHERE sr.sr_store_sk = s.s_store_sk
            AND dr.d_year = 1998
            AND regexp_like(i2.i_item_desc, 'Premium.*[0-9]{3}')
      )
    GROUP BY s.s_store_sk, s.s_store_name, s.s_division_name, s.s_city
),
store_category AS (
    SELECT 
        pi.ss_store_sk,
        MIN(i.i_category) AS category
    FROM premium_items pi
    JOIN item i ON pi.ss_item_sk = i.i_item_sk
    GROUP BY pi.ss_store_sk
),
avg_premium_profit AS (
    SELECT 
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, 'Premium.*[0-9]{3}')
)
SELECT 
    st.s_store_name,
    SUBSTRING(st.s_store_name FROM 1 FOR 5) AS store_name_prefix,
    st.s_city,
    st.s_division_name,
    st.total_net_profit,
    st.total_quantity,
    st.distinct_premium_items,
    CONCAT(st.s_store_name, ' - ', COALESCE(sc.category, 'Unknown')) AS store_category_concat,
    CASE 
        WHEN st.total_net_profit > ap.avg_net_profit THEN 'Above Avg' 
        ELSE 'Below Avg' 
    END AS profit_vs_average,
    (SELECT MAX(regexp_extract(i.i_item_desc, '(\\d{3})', 1))
     FROM premium_items pi2
     JOIN item i ON pi2.ss_item_sk = i.i_item_sk
     WHERE pi2.ss_store_sk = st.s_store_sk) AS extracted_code,
    RANK() OVER (PARTITION BY st.s_division_name ORDER BY st.total_net_profit DESC) AS rank_within_division
FROM store_totals st
LEFT JOIN store_category sc ON sc.ss_store_sk = st.s_store_sk
CROSS JOIN avg_premium_profit ap
ORDER BY rank_within_division, st.total_net_profit DESC
LIMIT 100
