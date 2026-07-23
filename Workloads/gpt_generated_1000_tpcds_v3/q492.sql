WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_ext_wholesale_cost,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        sr.sr_return_quantity,
        inv.inv_quantity_on_hand,
        cp.cp_catalog_page_number,
        cp.cp_department,
        wp.wp_url,
        wp.wp_link_count,
        (
            SELECT avg(ss2.ss_wholesale_cost)
            FROM store_sales ss2
            WHERE ss2.ss_item_sk = ss.ss_item_sk
        ) AS avg_item_wholesale_cost
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_customer_sk = c.c_customer_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        d.d_year = 2001
        AND t.t_hour BETWEEN 9 AND 17
        AND c.c_birth_country IN ('SWITZERLAND', 'MONACO')
        AND wp.wp_link_count > 10
        AND inv.inv_quantity_on_hand < 100
        AND ss.ss_ext_wholesale_cost > 1000
        AND cp.cp_department = 'Books'
),
profit_rank AS (
    SELECT
        *,
        SUM(ss_net_profit) OVER (PARTITION BY c_customer_sk, d_year) AS cust_year_profit
    FROM base
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    d_month_seq,
    t_hour,
    ss_ticket_number,
    ss_net_paid,
    ss_net_profit,
    sr_return_quantity,
    inv_quantity_on_hand,
    cp_catalog_page_number,
    cp_department,
    wp_url,
    wp_link_count,
    avg_item_wholesale_cost,
    cust_year_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY cust_year_profit DESC) AS profit_rank_year
FROM profit_rank
ORDER BY profit_rank_year, c_customer_id
LIMIT 100
