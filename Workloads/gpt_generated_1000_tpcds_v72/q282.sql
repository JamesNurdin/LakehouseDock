WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        i.i_class AS class,
        td.t_meal_time AS meal_time,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_net_loss ELSE 0 END) AS total_store_return_loss,
        SUM(CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_net_loss ELSE 0 END) AS total_web_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_cnt,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    WHERE
        td.t_meal_time = 'dinner'
        AND ca.ca_state = 'CA'
        AND i.i_units = 'Pound'
        AND i.i_category_id IN (1, 3, 5)
        AND td.t_hour BETWEEN 17 AND 20
        AND EXISTS (
            SELECT 1
            FROM store_returns sr_check
            WHERE sr_check.sr_item_sk = ss.ss_item_sk
              AND sr_check.sr_return_quantity > 0
        )
    GROUP BY
        i.i_category,
        i.i_class,
        td.t_meal_time
)
SELECT
    category,
    class,
    meal_time,
    total_store_profit,
    total_store_return_loss,
    total_web_return_loss,
    (total_store_profit - total_store_return_loss - total_web_return_loss) AS net_profit_after_returns,
    CASE
        WHEN (total_store_profit - total_store_return_loss - total_web_return_loss) > 10000 THEN 'High'
        ELSE 'Low'
    END AS profit_level
FROM sales_agg
WHERE (total_store_profit - total_store_return_loss - total_web_return_loss) > 5000
ORDER BY net_profit_after_returns DESC
LIMIT 100
