WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_ext_tax,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_addr_sk,
        ss.ss_promo_sk,
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_city,
        p.p_promo_name,
        p.p_cost,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_return_amount,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_returned_date_sk
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        OR cr.cr_returning_addr_sk = ca.ca_address_sk
)
SELECT
    ca_state,
    ca_city,
    p_promo_name,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0)) AS total_net_loss,
    CASE
        WHEN SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0)) > 5000 THEN 'HIGH_LOSS'
        ELSE 'LOW_LOSS'
    END AS loss_category,
    RANK() OVER (PARTITION BY ca_state ORDER BY SUM(COALESCE(cr_net_loss, 0) + COALESCE(sr_net_loss, 0)) DESC) AS state_loss_rank,
    (SELECT COUNT(DISTINCT p_sub.p_promo_id) FROM promotion p_sub WHERE p_sub.p_cost > 1000) AS costly_promo_cnt
FROM base
WHERE ss_ext_tax > 100
    AND p_cost > 1000
    AND cr_returned_date_sk IS NOT NULL
GROUP BY ca_state, ca_city, p_promo_name
HAVING SUM(ss_ext_sales_price) > 2000
ORDER BY total_net_loss DESC, state_loss_rank
LIMIT 100
