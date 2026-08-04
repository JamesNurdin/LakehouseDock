WITH sales_returns AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        sr.sr_returned_date_sk,
        sr.sr_store_credit,
        sr.sr_return_amt,
        sr.sr_reason_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_store_sk
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    d_sales.d_year,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Discount' ELSE 'No Discount' END AS discount_flag,
    COUNT(DISTINCT sr.ss_ticket_number) AS tickets_sold,
    SUM(COALESCE(sr.ss_ext_sales_price, 0)) AS total_sales,
    SUM(COALESCE(sr.sr_store_credit, 0)) AS total_store_credit,
    SUM(COALESCE(sr.ss_net_profit, 0)) AS total_net_profit
FROM sales_returns sr
JOIN store s
    ON sr.ss_store_sk = s.s_store_sk
LEFT JOIN store s_ret
    ON sr.sr_store_sk = s_ret.s_store_sk
JOIN promotion p
    ON sr.ss_promo_sk = p.p_promo_sk
JOIN date_dim d_sales
    ON sr.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN customer_demographics cd_sales
    ON sr.ss_cdemo_sk = cd_sales.cd_demo_sk
LEFT JOIN customer_demographics cd_return
    ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
JOIN household_demographics hd_sales
    ON sr.ss_hdemo_sk = hd_sales.hd_demo_sk
LEFT JOIN household_demographics hd_return
    ON sr.sr_hdemo_sk = hd_return.hd_demo_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN web_page wp_c
    ON wp_c.wp_creation_date_sk = d_promo_start.d_date_sk
JOIN web_page wp_a
    ON wp_a.wp_access_date_sk = d_promo_end.d_date_sk
WHERE sr.ss_ticket_number IN (
    SELECT ss_ticket_number FROM store_sales WHERE ss_net_profit > 0
    INTERSECT
    SELECT sr_ticket_number FROM store_returns WHERE sr_store_credit > 10
)
GROUP BY
    s.s_store_name,
    p.p_promo_name,
    d_sales.d_year,
    p.p_discount_active
ORDER BY total_sales DESC
LIMIT 100
