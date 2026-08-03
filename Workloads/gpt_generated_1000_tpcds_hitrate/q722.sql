WITH joined_data AS (
    SELECT
        st.s_store_sk,
        st.s_store_name,
        dw.d_year,
        dw.d_month_seq,
        ws.ws_net_paid,
        sr.sr_return_amt,
        c.c_customer_id,
        ca.ca_state,
        sm.sm_carrier
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE dr.d_year = 2001
      AND dw.d_year = 2001
      AND st.s_state = 'TX'
      AND sm.sm_carrier = 'UPS'
      AND ca.ca_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
),
aggregated AS (
    SELECT
        MAX(s_store_sk) AS s_store_sk,
        s_store_name,
        d_year,
        d_month_seq,
        SUM(ws_net_paid) AS total_sales,
        SUM(sr_return_amt) AS total_returns,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        CASE WHEN SUM(sr_return_amt) > 0 THEN 'Has Returns' ELSE 'No Returns' END AS return_flag
    FROM joined_data
    GROUP BY CUBE (s_store_name, d_year, d_month_seq)
    HAVING s_store_name IS NOT NULL
)
SELECT
    DISTINCT s_store_name,
    d_year,
    d_month_seq,
    total_sales,
    total_returns,
    distinct_customers,
    return_flag,
    LAG(total_sales) OVER (PARTITION BY s_store_name ORDER BY d_month_seq) AS prev_month_sales,
    (total_sales - LAG(total_sales) OVER (PARTITION BY s_store_name ORDER BY d_month_seq)) AS sales_change,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank_year,
    (
        SELECT AVG(ws2.ws_net_paid)
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = aggregated.d_year
          AND d2.d_month_seq = aggregated.d_month_seq
    ) AS avg_monthly_sales
FROM aggregated
WHERE s_store_sk NOT IN (
    SELECT DISTINCT sr2.sr_store_sk
    FROM store_returns sr2
    WHERE sr2.sr_return_amt > 1000
)
ORDER BY sales_rank_year, s_store_name
