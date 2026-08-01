WITH sales_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_sk AS item_sk,
        i.i_product_name,
        d.d_year,
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
        regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_code
    FROM store_sales ss TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_product_name, '^.*[A-Z]{3}.*$')
      AND i.i_category LIKE '%wear%'
    GROUP BY i.i_item_id, i.i_item_sk, i.i_product_name, d.d_year, ca.ca_city, ca.ca_state
    HAVING SUM(ss.ss_ext_sales_price) > 0
),
returns_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_sk AS item_sk,
        d.d_year,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_item_sk, d.d_year
),
full_sales_returns AS (
    SELECT
        COALESCE(s.item_id, r.item_id) AS item_id,
        COALESCE(s.item_sk, r.item_sk) AS item_sk,
        COALESCE(s.d_year, r.d_year) AS year,
        s.total_sales,
        r.total_return_amt,
        s.sales_category,
        s.i_product_name,
        s.ca_city,
        s.ca_state,
        s.product_code
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.item_id = r.item_id AND s.d_year = r.d_year
),
web_returns_agg AS (
    SELECT
        i.i_item_id AS item_id,
        d.d_year,
        SUM(wr.wr_return_amt) AS web_return_amt,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, d.d_year
)
SELECT
    f.item_id,
    f.year,
    f.total_sales,
    f.total_return_amt,
    f.sales_category,
    l.city_prefix
FROM full_sales_returns f
CROSS JOIN LATERAL (
    SELECT substring(f.ca_city, 1, 3) AS city_prefix
) AS l
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN date_dim d2 ON wr.wr_returned_date_sk = d2.d_date_sk
    WHERE wr.wr_item_sk = f.item_sk
      AND d2.d_year = f.year
)
UNION DISTINCT
SELECT
    w.item_id,
    w.d_year AS year,
    CAST(null AS decimal(7,2)) AS total_sales,
    w.web_return_amt AS total_return_amt,
    'WEB' AS sales_category,
    CAST(null AS varchar) AS city_prefix
FROM web_returns_agg w
ORDER BY year DESC, total_sales DESC NULLS LAST
LIMIT 100
