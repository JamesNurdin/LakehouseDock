WITH sub1 AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ss.ss_net_paid)               AS total_spent,
        COUNT(*)                          AS txn_cnt
    FROM customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
                       AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
                         AND sr.sr_customer_sk = c.c_customer_sk
                         AND sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND i.i_manager_id IN (6, 13)
      AND s.s_country = 'United States'
      AND sr.sr_return_amt_inc_tax > 1000
      AND c.c_preferred_cust_flag = 'Y'
      AND i.i_brand IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
sub2 AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ss.ss_net_paid)               AS total_spent,
        COUNT(*)                          AS txn_cnt
    FROM customer c
    JOIN date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
                       AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND wp.wp_type = 'article'
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
      AND c.c_birth_country = 'United States'
      AND ss.ss_net_paid > 0
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
)
SELECT
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.d_year,
    t.total_spent,
    t.txn_cnt,
    RANK() OVER (PARTITION BY t.d_year ORDER BY t.total_spent DESC) AS yearly_rank
FROM (
    SELECT * FROM sub1
    INTERSECT
    SELECT * FROM sub2
) AS t
ORDER BY t.d_year DESC, yearly_rank
LIMIT 100
