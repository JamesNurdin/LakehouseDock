WITH base AS (
    SELECT
        cc.cc_employees,
        d.d_year,
        cr.cr_return_amount,
        ws.ws_net_paid,
        ws.ws_order_number,
        ca.ca_state,
        cd.cd_gender,
        p.p_discount_active,
        inv.inv_quantity_on_hand
    FROM call_center cc
    FULL OUTER JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN customer_address ca
        ON ca.ca_address_sk = cr.cr_refunded_addr_sk
    LEFT JOIN customer_demographics cd
        ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
),
agg1 AS (
    SELECT
        d_year,
        ca_state,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(inv_quantity_on_hand) AS total_inventory_onhand,
        COUNT(DISTINCT ws_order_number) AS orders_count
    FROM base
    WHERE
        d_year BETWEEN 2000 AND 2002
        AND ca_state IN ('WA', 'MT', 'UT')
        AND cd_gender = 'M'
        AND p_discount_active = 'Y'
        AND cc_employees > 50
    GROUP BY
        d_year,
        ca_state
    HAVING
        SUM(cr_return_amount) > 1000
)
SELECT
    d_year,
    ca_state,
    total_return_amount,
    total_net_paid,
    total_inventory_onhand,
    orders_count,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    AVG(total_return_amount) OVER () AS avg_return_amount_all,
    SUM(total_return_amount) OVER (
        PARTITION BY ca_state
        ORDER BY d_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_return_by_state
FROM agg1
ORDER BY total_return_amount DESC
LIMIT 100
