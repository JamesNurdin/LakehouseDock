WITH
    sales_agg AS (
        SELECT
            ss.ss_customer_sk,
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            SUM(ss.ss_net_paid) AS total_paid,
            COUNT(*) AS txn_cnt
        FROM store_sales ss
        WHERE ss.ss_net_paid > 0
        GROUP BY ss.ss_customer_sk, ss.ss_sold_date_sk, ss.ss_sold_time_sk
    ),
    inventory_agg AS (
        SELECT
            inv.inv_date_sk,
            SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory inv
        WHERE inv.inv_quantity_on_hand > 0
        GROUP BY inv.inv_date_sk
    ),
    eligible_customers AS (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_birth_year BETWEEN 1960 AND 1970
        INTERSECT
        SELECT wp.wp_customer_sk
        FROM web_page wp
        WHERE wp.wp_autogen_flag = 'Y'
    ),
    base AS (
        SELECT
            d.d_year,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            hd.hd_income_band_sk,
            c.c_preferred_cust_flag,
            SUM(sa.total_paid) AS sum_total_paid,
            SUM(sa.txn_cnt) AS sum_txn_cnt
        FROM sales_agg sa
        JOIN customer c
            ON sa.ss_customer_sk = c.c_customer_sk
        JOIN eligible_customers ec
            ON c.c_customer_sk = ec.c_customer_sk
        JOIN date_dim d
            ON sa.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t
            ON sa.ss_sold_time_sk = t.t_time_sk
        JOIN household_demographics hd
            ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN inventory_agg inva
            ON d.d_date_sk = inva.inv_date_sk
        JOIN web_site ws
            ON ws.web_open_date_sk = d.d_date_sk
        JOIN web_page wp
            ON wp.wp_customer_sk = c.c_customer_sk
            AND wp.wp_creation_date_sk = d.d_date_sk
        LEFT JOIN LATERAL (
            SELECT MAX(ss2.ss_sold_date_sk) AS last_sale_date_sk
            FROM store_sales ss2
            WHERE ss2.ss_customer_sk = c.c_customer_sk
        ) AS last_sale ON TRUE
        WHERE d.d_date >= DATE '2001-01-01'
          AND d.d_date < DATE '2002-01-01'
          AND t.t_hour BETWEEN 9 AND 17
          AND ib.ib_upper_bound >= 150000
          AND hd.hd_income_band_sk IN (2, 7)
        GROUP BY ROLLUP (
            d.d_year,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            hd.hd_income_band_sk,
            c.c_preferred_cust_flag
        )
    )
SELECT
    base.d_year,
    base.ib_lower_bound,
    base.ib_upper_bound,
    base.hd_income_band_sk,
    base.c_preferred_cust_flag,
    base.sum_total_paid,
    base.sum_txn_cnt,
    RANK() OVER (PARTITION BY base.d_year ORDER BY base.sum_total_paid DESC) AS revenue_rank
FROM base
ORDER BY base.d_year NULLS LAST, base.sum_total_paid DESC
LIMIT 100
