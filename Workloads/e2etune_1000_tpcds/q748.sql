WITH returns_agg AS (
    SELECT
        c.c_birth_country AS country,
        d.d_year AS year,
        d.d_quarter_name AS quarter,
        wp.wp_type AS page_type,
        COUNT(*) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_quantity,
        AVG(wr.wr_net_loss) AS avg_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND d.d_year BETWEEN 2010 AND 2020
      AND wp.wp_type IN ('product', 'category')
    GROUP BY c.c_birth_country, d.d_year, d.d_quarter_name, wp.wp_type
    HAVING COUNT(*) >= 5
)
SELECT
    country,
    year,
    quarter,
    page_type,
    total_returns,
    total_quantity,
    avg_net_loss,
    total_return_amount,
    RANK() OVER (PARTITION BY year, quarter ORDER BY avg_net_loss DESC) AS net_loss_rank
FROM returns_agg
ORDER BY avg_net_loss DESC
LIMIT 20
