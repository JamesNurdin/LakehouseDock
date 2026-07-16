WITH return_agg AS (
    SELECT
        d_ret.d_year AS return_year,
        s.s_store_sk,
        s.s_store_name,
        w.web_site_sk,
        w.web_name,
        d_web_close.d_date AS site_close_date,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        COUNT(DISTINCT ca_ret.ca_address_sk) AS distinct_returning_addresses,
        COUNT(DISTINCT ca_ref.ca_address_sk) AS distinct_refunded_addresses,
        MIN(d_ret.d_date) AS earliest_return_date,
        MAX(d_ret.d_date) AS latest_return_date
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_web_close
        ON w.web_close_date_sk = d_web_close.d_date_sk
    WHERE d_ret.d_year BETWEEN 2000 AND 2005
    GROUP BY
        d_ret.d_year,
        s.s_store_sk,
        s.s_store_name,
        w.web_site_sk,
        w.web_name,
        d_web_close.d_date
)
SELECT
    ra.return_year,
    ra.s_store_name,
    ra.web_name,
    ra.num_returns,
    ra.total_return_amount,
    ra.total_net_loss,
    ra.avg_return_quantity,
    ra.total_refunded_cash,
    ra.distinct_returning_addresses,
    ra.distinct_refunded_addresses,
    ra.earliest_return_date,
    ra.latest_return_date,
    ra.site_close_date,
    DATE_DIFF('day', ra.earliest_return_date, ra.site_close_date) AS days_to_site_close,
    ROW_NUMBER() OVER (PARTITION BY ra.return_year ORDER BY ra.total_net_loss DESC) AS loss_rank
FROM return_agg ra
WHERE ra.total_return_amount > 1000
ORDER BY ra.return_year, loss_rank
LIMIT 100
