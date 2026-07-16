WITH filtered_returns AS (
    SELECT
        cr.cr_returning_customer_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ca_returning.ca_country AS returning_country,
        ca_refunded.ca_country AS refunded_country,
        cp.cp_type,
        cp.cp_start_date_sk,
        cp.cp_end_date_sk,
        w.w_city,
        w.w_country
    FROM catalog_returns cr
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE ca_returning.ca_country = 'United States'
      AND cp.cp_start_date_sk >= 2450800
      AND cp.cp_end_date_sk <= 2451100
)
SELECT
    w_city,
    cp_type,
    COUNT(*) AS total_returns,
    SUM(cr_net_loss) AS total_net_loss,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT cr_returning_customer_sk) AS distinct_returning_customers,
    RANK() OVER (ORDER BY SUM(cr_net_loss) DESC) AS loss_rank
FROM filtered_returns
GROUP BY w_city, cp_type
HAVING SUM(cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 10
