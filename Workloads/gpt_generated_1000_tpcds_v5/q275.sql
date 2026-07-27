WITH sales_agg AS (
    SELECT
        d.d_year,
        c.c_customer_id,
        ca.ca_state,
        cc.cc_market_manager,
        SUM(ss.ss_net_paid_inc_tax) AS total_paid,
        SUM(ss.ss_quantity) AS total_qty,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND ss.ss_quantity > 30
      AND ss.ss_net_paid_inc_tax >= 500
      AND cc.cc_market_manager IS NOT NULL
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND c.c_birth_year BETWEEN 1950 AND 1970
    GROUP BY d.d_year, c.c_customer_id, ca.ca_state, cc.cc_market_manager
)
SELECT
    d_year,
    c_customer_id,
    ca_state,
    cc_market_manager,
    total_paid,
    total_qty,
    sales_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_paid DESC) AS revenue_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_qty DESC) AS qty_row_num,
    CASE WHEN total_paid > 10000 THEN 'High' ELSE 'Medium' END AS revenue_category
FROM sales_agg
ORDER BY d_year, revenue_rank
LIMIT 100
