WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        w.w_state,
        w.w_warehouse_sq_ft,
        c.c_customer_sk,
        c.c_birth_year,
        ca.ca_county,
        p.p_discount_active,
        r.r_reason_desc,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        wp.wp_url
    FROM store_sales ss
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
        ON c.c_customer_sk = wp.wp_customer_sk
    WHERE i.i_current_price > 50
      AND c.c_birth_year BETWEEN 1970 AND 1980
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        i_category,
        w_state,
        SUM(ss_quantity) AS total_quantity_sold,
        SUM(ss_net_paid) AS total_sales,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(ss_net_profit) - SUM(sr_return_amt) AS net_profit,
        CASE WHEN (SUM(ss_net_profit) - SUM(sr_return_amt)) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
        COUNT(DISTINCT c_customer_sk) AS unique_customers
    FROM base
    GROUP BY CUBE (i_category, w_state)
    HAVING SUM(ss_net_paid) > 1000
)
SELECT
    a.i_category,
    a.w_state,
    a.total_quantity_sold,
    a.total_sales,
    a.total_return_amount,
    a.net_profit,
    a.profit_flag,
    a.unique_customers,
    ROW_NUMBER() OVER (PARTITION BY a.i_category ORDER BY a.net_profit DESC) AS profit_rank,
    (SELECT AVG(b.net_profit) FROM agg b WHERE b.i_category = a.i_category) AS avg_category_profit
FROM agg a
ORDER BY a.i_category, a.w_state
