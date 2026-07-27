WITH return_summary AS (
    SELECT
        c.c_customer_id,
        i.i_brand,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_tickets,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items,
        CASE 
            WHEN SUM(sr.sr_return_amt) > SUM(wr.wr_return_amt) THEN 'STORE_HIGH'
            ELSE 'WEB_HIGH'
        END AS higher_return_source
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_second > 5
      AND i.i_current_price BETWEEN 10 AND 100
      AND p.p_discount_active = 'Y'
    GROUP BY c.c_customer_id, i.i_brand
)
SELECT
    higher_return_source,
    AVG(total_store_return_amt) AS avg_store_return,
    AVG(total_web_return_amt) AS avg_web_return,
    COUNT(*) AS num_customer_brand_groups
FROM return_summary
WHERE total_store_return_amt > 0
GROUP BY higher_return_source
ORDER BY avg_store_return DESC
LIMIT 100
