WITH returns_by_addr_date AS (
    SELECT 
        cr.cr_refunded_addr_sk AS address_sk,
        cr.cr_returned_date_sk AS return_date_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_refunded_addr_sk, cr.cr_returned_date_sk
)
SELECT
    ss.ss_sold_date_sk AS sale_date_sk,
    st.s_store_id,
    st.s_store_name,
    ca.ca_city,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_return_net_loss,
    ss.ss_net_profit - COALESCE(r.total_net_loss, 0) AS net_effect,
    CASE 
        WHEN ss.ss_net_profit - COALESCE(r.total_net_loss, 0) > 0 THEN 'PROFIT'
        WHEN ss.ss_net_profit - COALESCE(r.total_net_loss, 0) = 0 THEN 'BREAK-EVEN'
        ELSE 'LOSS'
    END AS net_effect_category,
    ROW_NUMBER() OVER (PARTITION BY st.s_store_id ORDER BY ss.ss_sold_date_sk DESC) AS recent_sale_rank
FROM store_sales ss
JOIN store st ON ss.ss_store_sk = st.s_store_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN returns_by_addr_date r 
    ON r.address_sk = ca.ca_address_sk 
    AND r.return_date_sk = ss.ss_sold_date_sk
WHERE ss.ss_sold_date_sk IS NOT NULL
ORDER BY st.s_store_id, ss.ss_sold_date_sk DESC
