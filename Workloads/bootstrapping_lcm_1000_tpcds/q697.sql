WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_class,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        MAX(cr.cr_return_amt_inc_tax) AS max_return_amt_inc_tax,
        MIN(cr.cr_return_tax) AS min_return_tax,
        COUNT(*) FILTER (WHERE ca_refunded.ca_state = ca_returning.ca_state) AS same_state_returns,
        COUNT(*) FILTER (WHERE ca_refunded.ca_state <> ca_returning.ca_state) AS cross_state_returns,
        SUM(CASE WHEN ca_refunded.ca_country = 'United States' THEN 1 ELSE 0 END) AS us_refunded_returns,
        SUM(CASE WHEN ca_returning.ca_country = 'United States' THEN 1 ELSE 0 END) AS us_returning_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2010 AND 2015
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_class
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.s_store_name,
    agg.s_state,
    agg.i_category,
    agg.i_class,
    agg.total_return_amount,
    agg.total_fee,
    agg.total_net_loss,
    agg.distinct_orders,
    agg.avg_return_qty,
    agg.max_return_amt_inc_tax,
    agg.min_return_tax,
    agg.same_state_returns,
    agg.cross_state_returns,
    agg.us_refunded_returns,
    agg.us_returning_returns,
    RANK() OVER (PARTITION BY agg.s_store_name ORDER BY agg.total_return_amount DESC) AS store_return_rank
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
