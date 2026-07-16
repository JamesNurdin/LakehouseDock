WITH agg AS (
    SELECT
        d_ret.d_year AS return_year,
        i.i_category AS item_category,
        i.i_brand AS item_brand,
        MIN(s.s_store_name) AS store_name,
        MIN(ca_refunded.ca_city) AS refunded_city,
        MIN(ca_returning.ca_city) AS returning_city,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    GROUP BY
        d_ret.d_year,
        i.i_category,
        i.i_brand
)
SELECT
    a.return_year,
    a.item_category,
    a.item_brand,
    a.store_name,
    a.refunded_city,
    a.returning_city,
    a.total_net_loss,
    a.return_count,
    a.rank_by_net_loss
FROM (
    SELECT
        agg.*,
        ROW_NUMBER() OVER (PARTITION BY return_year ORDER BY total_net_loss DESC) AS rank_by_net_loss
    FROM agg
) a
WHERE a.rank_by_net_loss <= 5
ORDER BY a.return_year DESC, a.rank_by_net_loss
