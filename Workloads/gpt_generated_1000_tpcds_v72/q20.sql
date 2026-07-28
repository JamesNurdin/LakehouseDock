WITH joined_data AS (
    SELECT
        cp.cp_department,
        td.t_hour,
        td.t_shift,
        ca.ca_state,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        cr.cr_return_amount
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE ss.ss_quantity > 1
      AND ss.ss_wholesale_cost > 10
      AND ss.ss_ext_sales_price > 100
      AND cr.cr_return_amount > 20
      AND cp.cp_department IN ('Books', 'Electronics')
      AND ca.ca_state = 'CA'
      AND td.t_hour BETWEEN 8 AND 20
),
aggregated AS (
    SELECT
        cp_department,
        t_hour,
        ca_state,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        SUM(ss_net_profit) - SUM(cr_return_amount) AS net_contribution
    FROM joined_data
    GROUP BY ROLLUP (cp_department, t_hour, ca_state)
)
SELECT
    cp_department,
    t_hour,
    ca_state,
    total_sales,
    total_returns,
    net_contribution,
    RANK() OVER (PARTITION BY cp_department ORDER BY total_sales DESC) AS sales_rank_dept,
    SUM(total_sales) OVER (PARTITION BY cp_department ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_by_hour
FROM aggregated
ORDER BY cp_department NULLS LAST,
         t_hour NULLS LAST,
         ca_state NULLS LAST
LIMIT 100
