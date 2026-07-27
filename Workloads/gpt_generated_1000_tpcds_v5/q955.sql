WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1910
      AND ss.ss_quantity > 1
      AND ss.ss_ext_sales_price > 100
      AND ca.ca_country = 'United States'
      AND ca.ca_state = 'CA'
    GROUP BY ss.ss_store_sk, d.d_year
),
store_ret_agg AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        d.d_year AS year,
        SUM(sr.sr_net_loss) AS total_store_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1910
      AND sr.sr_return_quantity > 0
      AND ca.ca_state = 'CA'
    GROUP BY sr.sr_store_sk, d.d_year
),
web_ret_agg AS (
    SELECT
        d.d_year AS year,
        SUM(wr.wr_net_loss) AS total_web_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 1910
      AND wr.wr_return_quantity > 0
      AND ca.ca_state = 'CA'
    GROUP BY d.d_year
)
SELECT
    s.store_sk,
    s.year,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_store_return_loss, 0) AS total_store_return_loss,
    COALESCE(w.total_web_return_loss, 0) AS total_web_return_loss,
    (s.total_profit - COALESCE(r.total_store_return_loss, 0) - COALESCE(w.total_web_return_loss, 0)) AS net_contribution,
    CASE
        WHEN (s.total_profit - COALESCE(r.total_store_return_loss, 0) - COALESCE(w.total_web_return_loss, 0)) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS contribution_sign,
    ROW_NUMBER() OVER (PARTITION BY s.year ORDER BY (s.total_profit - COALESCE(r.total_store_return_loss, 0) - COALESCE(w.total_web_return_loss, 0)) DESC) AS store_rank_year
FROM sales_agg s
LEFT JOIN store_ret_agg r
    ON s.store_sk = r.store_sk AND s.year = r.year
LEFT JOIN web_ret_agg w
    ON s.year = w.year
ORDER BY s.year, store_rank_year
LIMIT 100
