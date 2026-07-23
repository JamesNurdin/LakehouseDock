WITH base_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        d.d_year,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    CROSS JOIN web_site w
    JOIN date_dim d_web
        ON w.web_open_date_sk = d_web.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_current_year = 'Y'
        AND d_closed.d_current_year = 'N'
        AND s.s_state IN ('CA', 'NY')
        AND s.s_gmt_offset BETWEEN -8.00 AND -5.00
        AND w.web_mkt_class LIKE '%services%'
        AND w.web_tax_percentage < 10
        AND ss.ss_ext_discount_amt > 0
        AND ss.ss_ext_sales_price > 1000
        AND cr.cr_return_quantity > 0
    GROUP BY
        s.s_store_id,
        s.s_state,
        d.d_year
)
SELECT
    ba.s_store_id,
    ba.s_state,
    ba.d_year,
    ba.total_net_profit,
    ba.total_sales_price,
    ba.total_return_amt_inc_tax,
    ba.total_net_paid_inc_tax,
    (ba.total_net_profit - ba.total_return_amt_inc_tax) AS net_profit_after_returns,
    avg_year.avg_total_net_profit,
    (SELECT COUNT(DISTINCT web_site_id) FROM web_site WHERE web_mkt_class LIKE '%services%') AS total_service_web_sites
FROM base_agg ba
JOIN (
    SELECT
        d_year,
        AVG(total_net_profit) AS avg_total_net_profit
    FROM base_agg
    GROUP BY d_year
) avg_year
    ON ba.d_year = avg_year.d_year
WHERE ba.total_net_profit > avg_year.avg_total_net_profit
ORDER BY net_profit_after_returns DESC
LIMIT 100
