WITH sales_by_store AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        td.t_hour,
        CASE
            WHEN ss.ss_net_profit > 0 THEN 'POSITIVE'
            WHEN ss.ss_net_profit = 0 THEN 'ZERO'
            ELSE 'NEGATIVE'
        END AS profit_flag,
        REGEXP_EXTRACT(s.s_store_name, 'Store ([A-Z]+)', 1) AS store_code
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE regexp_like(s.s_store_name, '^Store [A-Z]+')
      AND s.s_city LIKE '%York%'
)
SELECT
    s_store_name,
    s_city,
    store_code,
    CONCAT(s_city, '-', store_code) AS location_code,
    COUNT(*) AS sales_cnt,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(CASE WHEN profit_flag = 'POSITIVE' THEN ss_net_profit ELSE 0 END) AS positive_profit,
    MAX(t_hour) AS max_hour
FROM sales_by_store
GROUP BY
    s_store_name,
    s_city,
    store_code,
    CONCAT(s_city, '-', store_code)
ORDER BY total_sales DESC
LIMIT 100
