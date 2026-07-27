/*
Goal: Compute per‑customer, per‑hour return statistics for preferred customers born in June who made sizable returns, including a representative web page URL when available. The query joins all four tables, applies five selective filters, aggregates measures, filters groups with HAVING, orders the results, and limits to the top 100 rows.
*/
WITH filtered AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        c.c_birth_month,
        sr.sr_return_amt_inc_tax,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        t.t_hour,
        t.t_meal_time,
        wp.wp_url
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
           AND wp.wp_type = 'article'  -- preserve outer join, only keep article pages when present
    WHERE c.c_birth_month = 6                     -- filter: born in June
      AND c.c_preferred_cust_flag = 'Y'           -- filter: preferred customers
      AND sr.sr_return_amt_inc_tax >= 100.00      -- filter: return amount (incl. tax) >= 100
      AND t.t_hour BETWEEN 9 AND 14               -- filter: business‑hour returns
      AND sr.sr_return_quantity > 1               -- filter: more than one item returned
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    t_hour,
    t_meal_time,
    COUNT(DISTINCT sr_ticket_number) AS return_transactions,
    SUM(sr_return_amt_inc_tax) AS total_return_amount,
    AVG(sr_return_amt_inc_tax) AS avg_return_amount,
    MIN(sr_return_amt_inc_tax) AS min_return_amount,
    MAX(sr_return_amt_inc_tax) AS max_return_amount,
    COALESCE(wp_url, 'N/A') AS representative_page_url
FROM filtered
GROUP BY
    c_customer_id,
    c_first_name,
    c_last_name,
    t_hour,
    t_meal_time,
    wp_url
HAVING SUM(sr_return_amt_inc_tax) > 500      -- keep only groups with substantial total loss
ORDER BY total_return_amount DESC
LIMIT 100
