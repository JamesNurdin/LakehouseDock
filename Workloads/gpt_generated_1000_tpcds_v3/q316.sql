WITH store_sales_agg AS (
    SELECT
        st.s_store_id,
        st.s_store_name,
        st.s_state,
        st.s_gmt_offset,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_count
    FROM store_sales ss
    INNER JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    WHERE
        st.s_state = 'CA'                                           -- 1
        AND st.s_gmt_offset BETWEEN -8.00 AND -5.00                 -- 2
        AND st.s_tax_percentage >= 5.00                            -- 3
        AND st.s_rec_start_date <= DATE '2002-12-31'                -- 4
        AND st.s_rec_end_date >= DATE '2002-01-01'                  -- 5
        AND ss.ss_ext_sales_price > 500.00                         -- 6
        AND ss.ss_quantity >= 1                                    -- 7
        AND EXISTS (
            SELECT 1
            FROM customer_address ca
            WHERE ca.ca_address_sk = ss.ss_addr_sk
              AND ca.ca_state = 'CA'                               -- 8
              AND ca.ca_location_type = 'apartment'                -- 9
              AND ca.ca_city IN ('Jackson', 'Woodland Poplar')      -- 10
        )
    GROUP BY
        st.s_store_id,
        st.s_store_name,
        st.s_state,
        st.s_gmt_offset
)
SELECT
    ssa.s_store_id,
    ssa.s_store_name,
    ssa.s_state,
    ssa.s_gmt_offset,
    ssa.total_net_profit,
    ssa.total_sales,
    ssa.sales_count,
    CASE
        WHEN ssa.total_net_profit > 100000.00 THEN 'high'
        WHEN ssa.total_net_profit > 50000.00 THEN 'medium'
        ELSE 'low'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY ssa.s_state ORDER BY ssa.total_net_profit DESC) AS rn_state,
    SUM(ssa.total_net_profit) OVER (
        PARTITION BY ssa.s_state
        ORDER BY ssa.total_net_profit
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_3_net_profit
FROM store_sales_agg ssa
ORDER BY ssa.total_net_profit DESC
LIMIT 100
