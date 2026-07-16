WITH city_brand_sales AS (
    SELECT
        s.s_city,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE i.i_manufact_id IN (52, 294)
      AND s.s_state = 'CA'
      AND ss.ss_quantity > 0
    GROUP BY s.s_city, i.i_brand
),
city_totals AS (
    SELECT
        s_city,
        SUM(total_profit) AS city_profit_total
    FROM city_brand_sales
    GROUP BY s_city
)
SELECT
    cbs.s_city,
    cbs.i_brand,
    cbs.total_sales,
    cbs.total_profit,
    cbs.num_transactions,
    cbs.avg_quantity,
    (cbs.total_profit / ct.city_profit_total) * 100 AS profit_share_pct,
    RANK() OVER (PARTITION BY cbs.s_city ORDER BY cbs.total_profit DESC) AS brand_profit_rank
FROM city_brand_sales cbs
JOIN city_totals ct ON cbs.s_city = ct.s_city
WHERE cbs.total_sales > 10000
ORDER BY cbs.s_city, brand_profit_rank
LIMIT 100
