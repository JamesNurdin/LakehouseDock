/*
Goal: Analyze the combined effect of catalog returns and web sales by call center and promotion, focusing on the year 2001, active promotions, larger call centers, and web pages with substantial content. The query joins all nine selected TPC‑DS tables, aggregates return amounts and net profit per call center and promotion, applies multiple filters, and returns the top results ordered by profit.
*/
WITH joined AS (
    SELECT
        cr.cr_return_amount               AS cr_return_amount,
        ws.ws_net_profit                  AS ws_net_profit,
        ws.ws_ext_sales_price             AS ws_ext_sales_price,
        cc.cc_call_center_id              AS cc_call_center_id,
        cc.cc_name                        AS cc_name,
        cc.cc_employees                   AS cc_employees,
        p.p_promo_id                      AS p_promo_id,
        p.p_promo_name                    AS p_promo_name,
        p.p_discount_active               AS p_discount_active,
        d_ret.d_year                      AS return_year,
        wp.wp_char_count                  AS wp_char_count
    FROM catalog_returns cr
    INNER JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    INNER JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk
    INNER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    INNER JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    /* Join a web sale that occurred on the same date as the return (allowed by the join rule) */
    INNER JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ret.d_date_sk
    INNER JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    INNER JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    INNER JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    /* Additional joins to satisfy the requirement of using all listed tables */
    INNER JOIN date_dim d_p_start
        ON p.p_start_date_sk = d_p_start.d_date_sk
    INNER JOIN date_dim d_p_end
        ON p.p_end_date_sk = d_p_end.d_date_sk
    INNER JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_employees,
    p_promo_id,
    p_promo_name,
    SUM(cr_return_amount)   AS total_return_amount,
    SUM(ws_net_profit)       AS total_net_profit,
    AVG(ws_ext_sales_price)  AS avg_sales_price,
    COUNT(*)                 AS transaction_count
FROM joined
WHERE
    return_year = 2001                     -- filter 1: specific year
    AND p_discount_active = 'Y'            -- filter 2: only active promotions
    AND cc_employees > 500                 -- filter 3: larger call centers
    AND wp_char_count > 2000               -- filter 4: rich‑content web pages
GROUP BY
    cc_call_center_id,
    cc_name,
    cc_employees,
    p_promo_id,
    p_promo_name
HAVING
    SUM(cr_return_amount) > 10000           -- keep only groups with sizable returns
ORDER BY
    total_net_profit DESC
LIMIT 100
