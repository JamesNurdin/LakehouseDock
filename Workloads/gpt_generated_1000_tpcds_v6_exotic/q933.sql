/*
Goal: Identify customers with high net sales ( > $10,000 ) after accounting for web returns, classify the sales level, and rank customers within each state by net paid amount.
The query joins all ten selected TPC‑DS tables, aggregates sales in a CTE, adds a sales class via CASE, aggregates web returns in a second CTE, left‑joins the return data, applies multiple filter predicates, uses a window function for ranking, and returns the top 100 rows.
*/
WITH base_sales AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        i.i_category,
        i.i_item_sk,
        p.p_promo_name,
        td.t_hour,
        SUM(ss.ss_net_paid)                         AS total_net_paid,
        SUM(ss.ss_quantity)                         AS total_qty,
        COUNT(DISTINCT ss.ss_ticket_number)         AS distinct_tickets,
        SUM(CASE WHEN ss.ss_ext_discount_amt > 0 THEN ss.ss_ext_discount_amt ELSE 0 END) AS total_discount
    FROM store_sales ss
    JOIN customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td              ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN store_returns sr    ON ss.ss_ticket_number = sr.sr_ticket_number
                                 AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r            ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        ca.ca_country = 'United States'               -- predicate 1
        AND i.i_current_price BETWEEN 10 AND 1000      -- predicate 2
        AND cd.cd_gender = 'M'                         -- predicate 3
        AND td.t_hour BETWEEN 8 AND 20                -- predicate 4
        AND p.p_discount_active = 'Y'                  -- predicate 5
    GROUP BY
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        i.i_category,
        i.i_item_sk,
        p.p_promo_name,
        td.t_hour
),
sales_with_class AS (
    SELECT
        *,
        CASE WHEN total_net_paid > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_class
    FROM base_sales
),
web_ret_agg AS (
    SELECT
        i.i_item_sk,
        td.t_hour,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*)               AS return_cnt
    FROM web_returns wr
    JOIN item i               ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td          ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY i.i_item_sk, td.t_hour
)
SELECT
    swc.c_customer_id,
    swc.ca_state,
    swc.sales_class,
    swc.total_net_paid,
    COALESCE(wr.total_return_amt, 0) AS total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY swc.ca_state ORDER BY swc.total_net_paid DESC) AS state_rank
FROM sales_with_class swc
LEFT JOIN web_ret_agg wr
    ON swc.i_item_sk = wr.i_item_sk
   AND swc.t_hour   = wr.t_hour
WHERE
    (swc.total_net_paid - COALESCE(wr.total_return_amt, 0)) > 5000   -- net after returns
    AND swc.total_qty >= 5                                           -- predicate 6
    AND swc.distinct_tickets >= 1                                    -- predicate 7
    AND swc.total_discount < 2000                                    -- predicate 8
    AND swc.sales_class = 'HIGH'                                     -- predicate 9
ORDER BY swc.total_net_paid DESC
LIMIT 100
