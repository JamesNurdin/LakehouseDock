WITH filtered_sales AS (
    SELECT
        ss.ss_net_profit,
        ss.ss_sold_time_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        i.i_manufact,
        s.s_city,
        t.t_hour
    FROM
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE
        regexp_like(i.i_manufact, 'tion')
        AND s.s_city LIKE '%County%'
        AND t.t_hour BETWEEN 8 AND 20
)
SELECT
    s_city,
    manufacturer_first_word,
    t_hour,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count,
    CONCAT(s_city, ' - ', manufacturer_first_word) AS city_manufacturer
FROM (
    SELECT
        s_city,
        regexp_extract(i_manufact, '^([^ ]+)', 1) AS manufacturer_first_word,
        t_hour,
        ss_net_profit AS net_profit
    FROM filtered_sales
) sub
GROUP BY ROLLUP (s_city, manufacturer_first_word, t_hour)
ORDER BY total_net_profit DESC NULLS LAST
LIMIT 100
