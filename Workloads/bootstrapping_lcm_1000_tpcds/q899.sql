SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter_label,
    SUM(cr.cr_net_loss)                         AS total_net_loss,
    SUM(cr.cr_return_amount)                    AS total_return_amount,
    COUNT(DISTINCT cr.cr_order_number)          AS distinct_orders,
    SUM(i.inv_quantity_on_hand)                 AS total_inventory_on_hand,
    COUNT(DISTINCT s.s_store_id)                AS closed_stores,
    COUNT(DISTINCT ws_open.web_site_id)         AS opened_web_sites,
    COUNT(DISTINCT ws_close.web_site_id)        AS closed_web_sites,
    AVG(cr.cr_return_quantity)                  AS avg_return_quantity,
    MAX(cr.cr_fee)                              AS max_fee,
    MIN(cr.cr_return_tax)                       AS min_return_tax
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws_open
    ON ws_open.web_open_date_sk = d.d_date_sk
JOIN web_site ws_close
    ON ws_close.web_close_date_sk = d.d_date_sk
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY d.d_date DESC
LIMIT 100
