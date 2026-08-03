WITH sample_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_customer_sk,
        ss_addr_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_ticket_number,
        ss_item_sk,
        ss_net_paid,
        ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    promotion.p_promo_name,
    store.s_store_name,
    store.s_state,
    reason.r_reason_desc,
    COUNT(DISTINCT sample_sales.ss_ticket_number) AS num_transactions,
    SUM(sample_sales.ss_net_paid) AS total_sales,
    SUM(sample_sales.ss_net_profit) AS total_profit,
    SUM(COALESCE(store_returns.sr_net_loss, 0)) AS store_return_loss,
    SUM(COALESCE(catalog_returns.cr_net_loss, 0)) AS catalog_return_loss,
    SUM(COALESCE(web_returns.wr_net_loss, 0)) AS web_return_loss,
    MIN(sample_sales.ss_net_paid) AS min_sale,
    MAX(sample_sales.ss_net_paid) AS max_sale
FROM sample_sales
RIGHT OUTER JOIN promotion
    ON sample_sales.ss_promo_sk = promotion.p_promo_sk
INNER JOIN time_dim
    ON sample_sales.ss_sold_time_sk = time_dim.t_time_sk
INNER JOIN customer
    ON sample_sales.ss_customer_sk = customer.c_customer_sk
INNER JOIN customer_address
    ON sample_sales.ss_addr_sk = customer_address.ca_address_sk
INNER JOIN store
    ON sample_sales.ss_store_sk = store.s_store_sk
LEFT JOIN store_returns
    ON store_returns.sr_ticket_number = sample_sales.ss_ticket_number
   AND store_returns.sr_item_sk = sample_sales.ss_item_sk
FULL OUTER JOIN reason
    ON store_returns.sr_reason_sk = reason.r_reason_sk
INNER JOIN catalog_returns
    ON catalog_returns.cr_returned_time_sk = time_dim.t_time_sk
   AND catalog_returns.cr_reason_sk = reason.r_reason_sk
INNER JOIN catalog_page
    ON catalog_returns.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
INNER JOIN ship_mode
    ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
INNER JOIN warehouse
    ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
INNER JOIN web_returns
    ON web_returns.wr_returned_time_sk = time_dim.t_time_sk
   AND web_returns.wr_reason_sk = reason.r_reason_sk
INNER JOIN web_page
    ON web_returns.wr_web_page_sk = web_page.wp_web_page_sk
WHERE
    time_dim.t_hour IN (9, 10, 11)
    AND store.s_state = 'CA'
    AND promotion.p_discount_active = 'Y'
    AND warehouse.w_state = 'TX'
    AND catalog_page.cp_department = 'Electronics'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = catalog_returns.cr_returned_date_sk
          AND cr2.cr_return_quantity > 5
    )
GROUP BY
    promotion.p_promo_name,
    store.s_store_name,
    store.s_state,
    reason.r_reason_desc
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
