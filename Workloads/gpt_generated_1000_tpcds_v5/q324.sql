WITH base AS (
    SELECT
        s.s_store_name,
        ws.web_name,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        AVG(cr.cr_return_quantity) AS avg_return_quantity,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory,
        SUM(cr.cr_store_credit) AS total_store_credit
    FROM catalog_returns cr
    JOIN date_dim dd
        ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = dd.d_date_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = dd.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2000
      AND ca.ca_country = 'United States'
      AND cr.cr_return_amount > 100
      AND hd.hd_income_band_sk >= 5
    GROUP BY s.s_store_name, ws.web_name
),
overall AS (
    SELECT AVG(sum_return_amount) AS avg_sum_return_amount
    FROM base
)
SELECT
    b.s_store_name,
    b.web_name,
    b.sum_return_amount,
    b.avg_return_quantity,
    b.total_inventory,
    b.total_store_credit,
    o.avg_sum_return_amount
FROM base b
CROSS JOIN overall o
WHERE b.sum_return_amount > o.avg_sum_return_amount
ORDER BY b.sum_return_amount DESC
LIMIT 100
