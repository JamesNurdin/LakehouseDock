/* goal: Identify customer demographic segments that had significant in‑store profit on catalog pages mentioning the word “economic” and also had notable web returns on pages whose URL contains “example.com”. The query demonstrates regex filtering, LIKE pattern matching, string concatenation, a Bernoulli sample, aggregation, and a set intersection of keys. */
WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),

sales_filtered AS (
    SELECT
        ss.ss_cdemo_sk AS cd_demo_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND regexp_like(cp.cp_description, '(?i)economic')
      AND concat(ca.ca_city, ', ', ca.ca_state) LIKE '%New%'
    GROUP BY ss.ss_cdemo_sk, cd.cd_gender, ca.ca_city, ca.ca_state
    HAVING SUM(ss.ss_net_profit) > 1000
),

returns_filtered AS (
    SELECT
        wr.wr_returning_cdemo_sk AS cd_demo_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND wp.wp_url LIKE '%example.com%'
      AND regexp_extract(wp.wp_type, '(\\w+)', 1) = 'home'
    GROUP BY wr.wr_returning_cdemo_sk, cd.cd_gender, ca.ca_city, ca.ca_state
    HAVING SUM(wr.wr_return_amt) > 500
),

intersected_demo AS (
    SELECT cd_demo_sk FROM sales_filtered
    INTERSECT
    SELECT cd_demo_sk FROM returns_filtered
)
SELECT
    id.cd_demo_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sf.total_profit) AS profit_sum,
    SUM(rf.total_return_amt) AS return_sum
FROM intersected_demo id
JOIN sales_filtered sf ON id.cd_demo_sk = sf.cd_demo_sk
JOIN returns_filtered rf ON id.cd_demo_sk = rf.cd_demo_sk
JOIN customer_demographics cd ON id.cd_demo_sk = cd.cd_demo_sk
GROUP BY id.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
ORDER BY profit_sum DESC
LIMIT 100
