WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        dd.d_year,
        dd.d_day_name,
        st.s_store_id,
        st.s_store_name,
        st.s_city,
        st.s_state,
        st.s_tax_percentage
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    WHERE regexp_like(st.s_store_name, '^A.*')               -- names starting with "A"
      AND st.s_store_name LIKE '%Store%'                     -- contains the word Store
      AND dd.d_current_week = 'N'                            -- current week flag
),
agg_sales AS (
    SELECT
        f.s_store_id,
        f.s_store_name,
        f.s_city,
        f.s_state,
        f.d_year,
        f.ss_store_sk,
        f.ss_sold_date_sk,
        SUM(f.ss_ext_sales_price) AS total_sales,
        SUM(f.ss_net_profit) AS total_profit,
        CASE WHEN SUM(f.ss_net_profit) >= 0 THEN 'POS' ELSE 'NEG' END AS profit_sign
    FROM filtered_sales f
    WHERE f.ss_item_sk NOT IN (
        SELECT ss3.ss_item_sk
        FROM store_sales ss3
        WHERE ss3.ss_quantity > 200
    )
    GROUP BY f.s_store_id, f.s_store_name, f.s_city, f.s_state, f.d_year,
             f.ss_store_sk, f.ss_sold_date_sk
)
SELECT
    t.s_store_id,
    t.s_store_name,
    t.s_city,
    t.s_state,
    t.d_year,
    CONCAT(t.s_store_name, ' - ', t.s_city) AS display_name,
    regexp_extract(t.s_store_name, '(\\d+)', 1) AS store_number,
    t.profit_sign,
    t.total_sales,
    t.total_profit,
    (
        SELECT SUM(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = t.ss_store_sk
          AND ss2.ss_sold_date_sk = t.ss_sold_date_sk
    ) AS daily_sales_total,
    t.rn
FROM (
    SELECT
        a.*, 
        ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_sales DESC) AS rn
    FROM agg_sales a
) t
WHERE t.rn <= 5
ORDER BY t.total_sales DESC
LIMIT 100
