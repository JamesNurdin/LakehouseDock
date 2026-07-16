SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_moy,
    total_net_loss,
    total_return_quantity,
    avg_return_amount,
    distinct_refunded_customers,
    distinct_returning_customers,
    refunded_city,
    returning_city,
    RANK() OVER (PARTITION BY d_year, d_moy ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_net_loss)                         AS total_net_loss,
        SUM(cr.cr_return_quantity)                  AS total_return_quantity,
        AVG(cr.cr_return_amount)                    AS avg_return_amount,
        COUNT(DISTINCT cr.cr_refunded_customer_sk)  AS distinct_refunded_customers,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
        MIN(ca_ref.ca_city)                         AS refunded_city,
        MIN(ca_ret.ca_city)                         AS returning_city
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy
) AS per_store_month
ORDER BY
    d_year DESC,
    d_moy DESC,
    net_loss_rank ASC
LIMIT 100
