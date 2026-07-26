SELECT
    st.s_store_id,
    st.s_store_name,
    ca.ca_city,
    ss.ss_sold_date_sk AS sale_date,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price AS sale_amount,
    COALESCE(cr.cr_return_amount,0) AS return_amount,
    ss.ss_net_profit,
    cr.cr_net_loss,
    ss.ss_net_profit - COALESCE(cr.cr_net_loss,0) AS net_profit_after_return,
    CASE 
        WHEN cr.cr_net_loss IS NULL THEN 'NO_RETURN'
        WHEN cr.cr_net_loss > ss.ss_net_profit THEN 'RETURN_EXCEEDS_SALE'
        ELSE 'RETURN_WITHIN_SALE'
    END AS return_status,
    RANK() OVER (PARTITION BY st.s_store_id ORDER BY ss.ss_sold_date_sk DESC) AS recent_sale_rank,
    SUM(ss.ss_ext_sales_price) OVER (PARTITION BY st.s_store_id ORDER BY ss.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_to_date,
    SUM(COALESCE(cr.cr_net_loss,0)) OVER (PARTITION BY st.s_store_id ORDER BY ss.ss_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_returns_to_date
FROM store_sales ss
JOIN store st ON ss.ss_store_sk = st.s_store_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_returns cr 
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk 
   AND cr.cr_returned_date_sk = ss.ss_sold_date_sk
WHERE ss.ss_sold_date_sk IS NOT NULL
ORDER BY st.s_store_id, ss.ss_sold_date_sk
