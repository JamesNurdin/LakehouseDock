WITH base AS (
    SELECT
        d.d_year,
        i.i_brand,
        i.i_item_sk,
        d.d_date_sk,
        cc.cc_name,
        cc.cc_state,
        cp.cp_department,
        cp.cp_type,
        sm.sm_carrier,
        p.p_cost,
        p.p_discount_active,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_order_number,
        wr.wr_order_number,
        inv.inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN household_demographics hd_return ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
        AND wr.wr_returning_hdemo_sk = hd_return.hd_demo_sk
        AND wr.wr_returning_addr_sk = ca_return.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#23'
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'monthly'
      AND sm.sm_carrier = 'DHL'
      AND p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        b.d_year,
        b.i_brand,
        b.cc_name,
        b.cp_department,
        SUM(b.cr_return_amount) AS total_return_amount,
        AVG(b.cr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT b.cr_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT b.wr_order_number) AS distinct_web_orders,
        MAX(b.inv_quantity_on_hand) AS max_inventory,
        MAX(b.p_cost) AS max_promo_cost,
        dr.daily_item_returns
    FROM base b
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS daily_item_returns
        FROM catalog_returns cr3
        WHERE cr3.cr_item_sk = b.i_item_sk
          AND cr3.cr_returned_date_sk = b.d_date_sk
    ) AS dr
    GROUP BY
        b.d_year,
        b.i_brand,
        b.cc_name,
        b.cp_department,
        dr.daily_item_returns
)
SELECT
    a.d_year,
    a.i_brand,
    a.cc_name,
    a.cp_department,
    a.total_return_amount,
    a.avg_return_tax,
    a.distinct_catalog_orders,
    a.distinct_web_orders,
    a.max_inventory,
    CASE WHEN a.max_promo_cost > 1000 THEN 'HIGH' ELSE 'LOW' END AS promo_cost_category,
    a.daily_item_returns,
    ROW_NUMBER() OVER (PARTITION BY a.i_brand ORDER BY a.total_return_amount DESC) AS brand_return_rank
FROM agg a
ORDER BY a.total_return_amount DESC
LIMIT 100
