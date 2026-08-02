WITH filtered_ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_ext_tax,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_bill_hdemo_sk,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        hd.hd_dep_count >= 5
        AND hd.hd_buy_potential IN ('>10000', '5001-10000')
        AND ws.ws_net_paid_inc_ship >= 5000.00
        AND ws.ws_ext_tax BETWEEN 10.00 AND 50.00
),
agg AS (
    SELECT
        fw.hd_buy_potential,
        fw.ib_lower_bound,
        fw.ib_upper_bound,
        COUNT(DISTINCT fw.ws_order_number) AS distinct_ws_orders,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_cr_orders,
        SUM(fw.ws_net_paid_inc_ship) AS total_ws_net_paid,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        AVG(fw.ws_ext_tax) AS avg_ws_ext_tax,
        MIN(cr.cr_return_quantity) AS min_return_qty,
        MAX(cr.cr_return_quantity) AS max_return_qty
    FROM
        filtered_ws fw
    JOIN catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = fw.hd_demo_sk
    GROUP BY
        fw.hd_buy_potential,
        fw.ib_lower_bound,
        fw.ib_upper_bound
)
SELECT
    a.hd_buy_potential,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.distinct_ws_orders,
    a.distinct_cr_orders,
    a.total_ws_net_paid,
    a.total_cr_return_amount,
    a.avg_ws_ext_tax,
    a.min_return_qty,
    a.max_return_qty,
    SUM(a.total_ws_net_paid) OVER (PARTITION BY a.hd_buy_potential) AS ws_net_paid_by_buy_potential,
    RANK() OVER (PARTITION BY a.hd_buy_potential ORDER BY a.total_ws_net_paid DESC) AS rank_by_net_paid
FROM
    agg a
ORDER BY
    a.hd_buy_potential,
    rank_by_net_paid
