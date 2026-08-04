WITH sales_agg AS (
    SELECT
        ca.ca_state,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM
        catalog_sales cs
        TABLESAMPLE BERNOULLI (10)  -- sample 10% of rows
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE
        i.i_manufact = 'callyeingeing'
        AND cs.cs_net_paid_inc_tax > 500
        AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY
        ca.ca_state
),

returns_agg AS (
    SELECT
        ca.ca_state,
        SUM(wr.wr_net_loss) AS total_returns,
        COUNT(*) AS returns_cnt
    FROM
        web_returns wr
        TABLESAMPLE BERNOULLI (5)  -- sample 5% of rows
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE
        i.i_manufact = 'callyeingeing'
        AND wr.wr_return_amt > 200
        AND r.r_reason_desc LIKE '%defect%'
        AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY
        ca.ca_state
),

combined AS (
    SELECT
        s.ca_state,
        s.total_sales,
        s.sales_cnt,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.returns_cnt, 0) AS returns_cnt,
        s.total_sales - COALESCE(r.total_returns, 0) AS net_margin,
        CASE WHEN COALESCE(r.total_returns, 0) = 0 THEN NULL
             ELSE s.total_sales / COALESCE(r.total_returns, 0) END AS sales_return_ratio
    FROM
        sales_agg s
        LEFT JOIN returns_agg r ON s.ca_state = r.ca_state
)

SELECT
    c.ca_state,
    c.total_sales,
    c.total_returns,
    c.net_margin,
    c.sales_return_ratio,
    (
        SELECT AVG(total_sales) FROM sales_agg
    ) AS avg_state_sales,
    (
        SELECT COUNT(*) FROM (
            SELECT ca_state FROM sales_agg
            EXCEPT
            SELECT ca_state FROM returns_agg
        ) diff_states
    ) AS states_without_returns
FROM
    combined c
WHERE
    c.total_sales > 2000
    AND c.total_returns < 3000
    AND c.sales_return_ratio IS NOT NULL
ORDER BY
    c.sales_return_ratio DESC,
    c.ca_state
