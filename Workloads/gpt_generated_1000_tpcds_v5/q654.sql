WITH agg_sales AS (
    SELECT
        ss.ss_store_sk,
        td.t_shift,
        ca.ca_state,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim td_ret ON sr.sr_return_time_sk = td_ret.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND ca.ca_country = 'United States'
      AND ss.ss_store_sk IN (40, 86, 217)
    GROUP BY ss.ss_store_sk, td.t_shift, ca.ca_state
), category_agg AS (
    SELECT
        store_sk,
        shift,
        profit_category,
        SUM(total_profit) AS cat_total_profit,
        SUM(sales_cnt) AS cat_sales_cnt
    FROM (
        SELECT
            ss_store_sk AS store_sk,
            t_shift AS shift,
            CASE WHEN total_profit > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
            total_profit,
            sales_cnt
        FROM agg_sales
    ) sub
    GROUP BY store_sk, shift, profit_category
)
SELECT
    store_sk,
    shift,
    profit_category,
    cat_total_profit,
    cat_sales_cnt,
    ROUND(cat_total_profit / NULLIF(cat_sales_cnt, 0), 2) AS avg_profit_per_sale
FROM category_agg
WHERE cat_total_profit > 5000
ORDER BY cat_total_profit DESC, avg_profit_per_sale DESC
LIMIT 100
