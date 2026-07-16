WITH customer_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        ss.ss_item_sk
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year = 1960
      AND c.c_preferred_cust_flag = 'Y'
),
store_return_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_customer_sk,
        sr.sr_ticket_number,
        sr.sr_item_sk,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_customer_sk, sr.sr_ticket_number, sr.sr_item_sk
),
customer_page_counts AS (
    SELECT
        wp_customer_sk AS c_customer_sk,
        COUNT(DISTINCT wp_web_page_sk) AS distinct_pages
    FROM web_page
    GROUP BY wp_customer_sk
)
SELECT
    s.s_store_id,
    s.s_city,
    date_add('day', cs.ss_sold_date_sk, DATE '1970-01-01') AS sold_date,
    SUM(cs.ss_net_profit) AS total_sales_profit,
    COALESCE(SUM(r.total_return_loss), 0) AS total_return_loss,
    SUM(cs.ss_net_profit) - COALESCE(SUM(r.total_return_loss), 0) AS net_contribution,
    COALESCE(SUM(cp.distinct_pages), 0) AS total_pages_visited,
    RANK() OVER (ORDER BY SUM(cs.ss_net_profit) - COALESCE(SUM(r.total_return_loss), 0) DESC) AS profit_rank
FROM customer_sales cs
JOIN store s ON cs.ss_store_sk = s.s_store_sk
LEFT JOIN store_return_agg r
    ON cs.ss_store_sk = r.sr_store_sk
    AND cs.ss_customer_sk = r.sr_customer_sk
    AND cs.ss_ticket_number = r.sr_ticket_number
    AND cs.ss_item_sk = r.sr_item_sk
LEFT JOIN customer_page_counts cp ON cs.ss_customer_sk = cp.c_customer_sk
GROUP BY s.s_store_id, s.s_city, date_add('day', cs.ss_sold_date_sk, DATE '1970-01-01')
HAVING SUM(cs.ss_net_profit) > 1000
ORDER BY net_contribution DESC
LIMIT 10
