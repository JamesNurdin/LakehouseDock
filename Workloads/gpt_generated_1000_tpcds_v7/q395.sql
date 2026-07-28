WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_tax,
        dd.d_date,
        dd.d_year,
        td.t_shift,
        ca.ca_location_type,
        ca.ca_city,
        inv.inv_quantity_on_hand,
        s.s_store_name,
        s.s_tax_percentage,
        ws.web_name,
        ws.web_gmt_offset
    FROM catalog_returns cr
    JOIN date_dim dd
      ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN time_dim td
      ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN inventory inv
      ON dd.d_date_sk = inv.inv_date_sk
    JOIN store s
      ON dd.d_date_sk = s.s_closed_date_sk
    JOIN web_site ws
      ON dd.d_date_sk = ws.web_open_date_sk
    WHERE dd.d_year = 2001
      AND td.t_shift = 'second'
      AND cr.cr_fee > 20
      AND cr.cr_return_tax > 0
      AND ca.ca_location_type = 'apartment'
      AND inv.inv_quantity_on_hand BETWEEN 10 AND 500
)
SELECT
    base.d_date AS return_date,
    base.t_shift,
    base.ca_location_type,
    base.s_store_name,
    base.web_name,
    base.cr_return_amount,
    base.cr_fee,
    base.inv_quantity_on_hand,
    base.s_tax_percentage,
    CASE
        WHEN base.cr_return_amount > 100 THEN 'HIGH'
        WHEN base.cr_return_amount > 50 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS amount_category,
    RANK() OVER (PARTITION BY base.d_date ORDER BY base.cr_return_amount DESC) AS daily_return_amount_rank,
    SUM(base.cr_return_amount) OVER (PARTITION BY base.s_store_name ORDER BY base.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_store_return_amount
FROM base
ORDER BY base.d_date ASC, daily_return_amount_rank
