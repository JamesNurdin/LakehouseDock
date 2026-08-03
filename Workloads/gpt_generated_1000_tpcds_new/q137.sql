WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_list_price > 50                -- predicate 1
      AND ss.ss_ext_tax BETWEEN 0 AND 250      -- predicate 2
      AND c.c_birth_year BETWEEN 1960 AND 1980-- predicate 3
    GROUP BY c.c_customer_sk, c.c_email_address, cd.cd_gender
),
return_agg AS (
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'order'                                 -- predicate 4
      AND wp.wp_rec_start_date >= DATE '1999-01-01'            -- predicate 5
      AND wp.wp_rec_start_date < DATE '2001-01-01'
      AND wr.wr_return_amt > 10
    GROUP BY wr.wr_refunded_customer_sk
)
SELECT
    sa.c_customer_sk,
    sa.c_email_address,
    sa.cd_gender,
    sa.total_sales,
    sa.total_profit,
    sa.sales_cnt,
    ra.return_cnt,
    CASE WHEN sa.total_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    RANK() OVER (ORDER BY sa.total_sales DESC) AS sales_rank,
    DENSE_RANK() OVER (PARTITION BY sa.cd_gender ORDER BY sa.total_profit DESC) AS profit_rank_by_gender
FROM sales_agg sa
LEFT JOIN return_agg ra
    ON ra.customer_sk = sa.c_customer_sk
WHERE sa.sales_cnt > 5
ORDER BY sales_rank
LIMIT 100
