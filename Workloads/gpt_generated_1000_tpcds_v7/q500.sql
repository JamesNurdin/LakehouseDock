WITH sales_agg AS (
    SELECT
        s.s_store_id            AS store_id,
        p.p_promo_name          AS promo_name,
        SUM(ss.ss_net_profit)   AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        SUM(sr.sr_return_amt)   AS total_return_amount
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cr.cr_return_ship_cost > 100
      AND s.s_geography_class = 'Unknown'
      AND s.s_rec_end_date > DATE '2000-01-01'
      AND c.c_birth_year BETWEEN 1970 AND 1980
    GROUP BY s.s_store_id, p.p_promo_name
)
SELECT
    store_id,
    AVG(total_net_profit)               AS avg_profit_per_promo,
    SUM(sales_transactions)              AS total_transactions,
    SUM(total_return_amount)             AS total_return_amount
FROM sales_agg
GROUP BY store_id
HAVING AVG(total_net_profit) > 500
ORDER BY avg_profit_per_promo DESC
LIMIT 10
