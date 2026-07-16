WITH agg AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_store_name AS s_store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        s.s_country AS store_country,
        d_return.d_year AS d_year,
        d_return.d_current_month AS d_current_month,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
        MIN(ca_return.ca_city) AS returning_city,
        MIN(ca_refund.ca_city) AS refunded_city,
        MIN(hd_return.hd_buy_potential) AS returning_buy_potential,
        MIN(hd_refund.hd_buy_potential) AS refunded_buy_potential,
        MIN(s.s_closed_date_sk) AS store_closed_date_sk,
        MIN(d_return.d_date) AS return_date_example
    FROM catalog_returns cr
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN household_demographics hd_return
        ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN household_demographics hd_refund
        ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN store s
        ON s.s_closed_date_sk = d_return.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country,
        d_return.d_year,
        d_return.d_current_month
)
SELECT
    s_store_id,
    s_store_name,
    store_city,
    store_state,
    store_country,
    d_year,
    d_current_month,
    total_net_loss,
    total_return_qty,
    avg_return_amount,
    distinct_items_returned,
    returning_city,
    refunded_city,
    returning_buy_potential,
    refunded_buy_potential,
    store_closed_date_sk,
    return_date_example,
    row_number() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS rank_within_year
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
