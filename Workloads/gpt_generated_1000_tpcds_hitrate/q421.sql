WITH ss_sample AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 1
),
joined AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        c.c_birth_year,
        c.c_birth_month,
        cc.cc_name AS call_center_name,
        cc.cc_country,
        wp.wp_type,
        wr.wr_return_amt,
        ws.web_name AS web_site_name,
        CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_level,
        ss.ss_net_profit,
        ss.ss_ext_sales_price
    FROM ss_sample ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk AND wp.wp_access_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
                              AND wr.wr_returned_date_sk = d.d_date_sk
                              AND wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND s.s_state = 'CA'
      AND c.c_birth_month = 5
      AND cc.cc_country = 'United States'
      AND wp.wp_type = 'Content'
)
SELECT
    ss_sold_date_sk,
    d_year,
    s_store_name,
    c_customer_id,
    return_level,
    SUM(ss_ext_sales_price) OVER (
        PARTITION BY s_store_name
        ORDER BY d_year
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS rolling_sales,
    ROW_NUMBER() OVER (
        PARTITION BY s_store_name
        ORDER BY ss_ext_sales_price DESC
    ) AS sales_rank,
    ss_net_profit
FROM joined
WHERE ss_ext_sales_price > 0
  AND ss_net_profit IS NOT NULL
  AND return_level = 'High'
  AND ss_sold_date_sk NOT IN (
        SELECT ss_sold_date_sk FROM store_sales WHERE ss_quantity = 0
   )
  AND ss_sold_date_sk IN (
        SELECT ss_sold_date_sk FROM store_sales
        EXCEPT
        SELECT ss_sold_date_sk FROM store_sales WHERE ss_quantity = 0
   )
ORDER BY sales_rank
LIMIT 100
