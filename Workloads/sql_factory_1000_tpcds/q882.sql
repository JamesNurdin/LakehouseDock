WITH sales_by_address AS (
    SELECT 
        ss.ss_addr_sk AS address_sk,
        st.s_store_id,
        ca.ca_city,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ss.ss_addr_sk, st.s_store_id, ca.ca_city
),
returns_by_address AS (
    SELECT 
        cr.cr_refunded_addr_sk AS address_sk,
        ca.ca_city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY cr.cr_refunded_addr_sk, ca.ca_city
)
SELECT
    s.address_sk,
    s.s_store_id,
    s.ca_city,
    s.total_sales,
    s.total_profit,
    r.total_return_amount,
    r.total_return_loss,
    CASE 
        WHEN r.total_return_loss > s.total_profit THEN 'OVERLOSS'
        WHEN r.total_return_loss > 0.5 * s.total_profit THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_severity,
    DENSE_RANK() OVER (ORDER BY r.total_return_loss DESC) AS loss_rank,
    s.sales_cnt,
    r.return_cnt,
    (s.total_sales - COALESCE(r.total_return_amount,0)) AS net_sales_after_returns
FROM sales_by_address s
LEFT JOIN returns_by_address r ON s.address_sk = r.address_sk
ORDER BY loss_rank
