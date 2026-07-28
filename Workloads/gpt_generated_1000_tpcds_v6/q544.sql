WITH ss_agg AS (
        SELECT
            ss.ss_customer_sk AS customer_sk,
            ss.ss_item_sk AS item_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_paid) AS total_net_paid,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        WHERE ss.ss_ext_tax > 30
          AND ss.ss_sales_price > 60
        GROUP BY ss.ss_customer_sk, ss.ss_item_sk
    ),
    wr_agg AS (
        SELECT
            wr.wr_refunded_customer_sk AS customer_sk,
            wr.wr_item_sk AS item_sk,
            wr.wr_web_page_sk,
            SUM(wr.wr_return_amt) AS total_return_amt,
            SUM(wr.wr_net_loss) AS total_return_loss,
            COUNT(*) AS return_cnt
        FROM web_returns wr
        WHERE wr.wr_return_amt > 0
        GROUP BY wr.wr_refunded_customer_sk, wr.wr_item_sk, wr.wr_web_page_sk
    )
SELECT
    c.c_customer_id,
    cd.cd_marital_status,
    i.i_brand,
    i.i_category,
    ss_agg.sales_cnt,
    ss_agg.total_sales,
    wr_agg.return_cnt,
    wr_agg.total_return_amt,
    (ss_agg.total_sales - wr_agg.total_return_amt) AS net_sales,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(i.i_current_price) AS min_item_price,
    MAX(i.i_current_price) AS max_item_price
FROM ss_agg
JOIN wr_agg
    ON ss_agg.customer_sk = wr_agg.customer_sk
   AND ss_agg.item_sk = wr_agg.item_sk
JOIN item i
    ON ss_agg.item_sk = i.i_item_sk
JOIN customer c
    ON ss_agg.customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON wr_agg.wr_web_page_sk = wp.wp_web_page_sk
WHERE c.c_birth_country IN ('MONACO', 'NEW ZEALAND')
  AND cd.cd_credit_rating = 'Good'
  AND cd.cd_dep_count = 0
  AND i.i_current_price BETWEEN 20 AND 80
  AND wp.wp_url LIKE '%example.com%'
GROUP BY
    c.c_customer_id,
    cd.cd_marital_status,
    i.i_brand,
    i.i_category,
    ss_agg.sales_cnt,
    ss_agg.total_sales,
    wr_agg.return_cnt,
    wr_agg.total_return_amt
ORDER BY net_sales DESC
LIMIT 100
