WITH returns_agg AS (
    SELECT
        d.d_year AS year,
        r.r_reason_desc AS reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        ib.ib_upper_bound AS income_upper_bound
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN income_band ib
        ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2000
        AND d.d_month_seq BETWEEN 1200 AND 1300
        AND cr.cr_fee > 50.00
        AND cr.cr_return_amount > 100.00
        AND p.p_discount_active = 'Y'
        AND ib.ib_upper_bound >= 50000
        AND ca_refunded.ca_state = 'CA'
        AND inv.inv_quantity_on_hand > 0
    GROUP BY
        d.d_year,
        r.r_reason_desc,
        ib.ib_upper_bound
)
SELECT
    ra.year,
    ra.reason_desc,
    ra.total_net_loss,
    ra.avg_net_loss,
    ra.total_inventory_qty,
    (SELECT MAX(ra2.total_net_loss)
     FROM returns_agg ra2
     WHERE ra2.reason_desc = ra.reason_desc) AS max_net_loss_for_reason
FROM returns_agg ra
WHERE ra.total_net_loss > (
    SELECT AVG(ra3.total_net_loss)
    FROM returns_agg ra3
    WHERE ra3.year = ra.year
)
ORDER BY ra.year DESC, ra.total_net_loss DESC
LIMIT 100
