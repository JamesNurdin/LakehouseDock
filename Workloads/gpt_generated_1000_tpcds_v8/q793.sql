WITH
    sales_base AS (
        SELECT
            s.s_store_id,
            s.s_store_sk,
            ib.ib_income_band_sk,
            ss.ss_ext_sales_price,
            ss.ss_net_profit,
            ss.ss_quantity
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE
            s.s_state = 'CA'
            AND ca.ca_gmt_offset = -8.00
            AND ib.ib_upper_bound <= 100000
            AND ss.ss_ext_sales_price > 1000.00
    ),
    sales_agg AS (
        SELECT
            s_store_id,
            ib_income_band_sk,
            SUM(ss_ext_sales_price) AS total_sales,
            SUM(ss_net_profit) AS total_profit,
            COUNT(*) AS txn_cnt
        FROM sales_base
        GROUP BY s_store_id, ib_income_band_sk
    ),
    union_set AS (
        SELECT s_store_id, ib_income_band_sk, total_sales, total_profit, txn_cnt FROM sales_agg
        UNION
        SELECT s_store_id, ib_income_band_sk, total_sales, total_profit, txn_cnt FROM sales_agg
        WHERE total_profit > 0
    ),
    no_webpage_customers AS (
        SELECT c.c_customer_sk
        FROM customer c
        EXCEPT
        SELECT wp.wp_customer_sk
        FROM web_page wp
    ),
    sales_with_nw AS (
        SELECT u.*, s.s_store_sk
        FROM union_set u
        JOIN store s ON s.s_store_id = u.s_store_id
        JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
        WHERE ss.ss_customer_sk IN (SELECT c_customer_sk FROM no_webpage_customers)
    ),
    rollup_agg AS (
        SELECT
            s_store_id,
            ib_income_band_sk,
            SUM(total_sales) AS sum_sales,
            SUM(total_profit) AS sum_profit,
            SUM(txn_cnt) AS sum_txn
        FROM sales_with_nw
        GROUP BY ROLLUP (s_store_id, ib_income_band_sk)
    )
SELECT
    s_store_id,
    ib_income_band_sk,
    sum_sales,
    sum_profit,
    sum_txn,
    ROW_NUMBER() OVER (ORDER BY sum_sales DESC) AS global_rn
FROM rollup_agg
ORDER BY s_store_id, ib_income_band_sk
LIMIT 100
