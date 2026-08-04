WITH
    filtered AS (
        SELECT
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_order_number,
            cr.cr_returned_date_sk,
            cr.cr_returned_time_sk,
            cr.cr_call_center_sk,
            cr.cr_refunded_customer_sk,
            cr.cr_refunded_addr_sk,
            cr.cr_refunded_hdemo_sk,
            d.d_year,
            d.d_month_seq,
            t.t_hour,
            cc.cc_call_center_id,
            cc.cc_gmt_offset,
            ca.ca_state,
            hd.hd_buy_potential,
            i.inv_quantity_on_hand,
            s.s_store_id,
            c.c_customer_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        JOIN inventory i ON i.inv_date_sk = d.d_date_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE d.d_year = 2001
          AND t.t_hour BETWEEN 12 AND 18
          AND cc.cc_gmt_offset = -5.00
          AND ca.ca_state = 'TX'
          AND hd.hd_buy_potential = '1001-5000'
          AND i.inv_quantity_on_hand > 0
          AND cr.cr_return_amount > 100
    ),
    returns_gt_200 AS (
        SELECT cr_order_number
        FROM filtered
        WHERE cr_return_amount > 200
    ),
    returns_qty_1 AS (
        SELECT cr_order_number
        FROM filtered
        WHERE cr_return_quantity = 1
    ),
    good_returns AS (
        SELECT f.*
        FROM filtered f
        WHERE f.cr_order_number IN (
            SELECT cr_order_number FROM returns_gt_200
            EXCEPT
            SELECT cr_order_number FROM returns_qty_1
        )
    ),
    base_with_lateral AS (
        SELECT
            g.*, 
            l.avg_qty
        FROM good_returns g
        LEFT JOIN LATERAL (
            SELECT AVG(cr_return_quantity) AS avg_qty
            FROM catalog_returns cr2
            WHERE cr2.cr_returning_customer_sk = g.c_customer_sk
        ) l ON TRUE
        WHERE EXISTS (
            SELECT 1
            FROM catalog_returns cr3
            WHERE cr3.cr_returning_customer_sk = g.c_customer_sk
              AND cr3.cr_return_amount > 150
        )
    ),
    agg_cc AS (
        SELECT
            cc.cc_call_center_id AS id,
            SUM(b.cr_return_amount) AS total_return_amount,
            COUNT(*) AS cnt
        FROM base_with_lateral b
        JOIN call_center cc ON b.cc_call_center_id = cc.cc_call_center_id
        GROUP BY cc.cc_call_center_id
    ),
    agg_store AS (
        SELECT
            s.s_store_id AS id,
            SUM(b.cr_return_amount) AS total_return_amount,
            COUNT(*) AS cnt
        FROM base_with_lateral b
        JOIN store s ON b.s_store_id = s.s_store_id
        GROUP BY s.s_store_id
    ),
    union_agg AS (
        SELECT * FROM agg_cc
        UNION
        SELECT * FROM agg_store
    ),
    ranked AS (
        SELECT
            id,
            total_return_amount,
            cnt,
            RANK() OVER (ORDER BY total_return_amount DESC) AS rnk,
            CASE WHEN RANK() OVER (ORDER BY total_return_amount DESC) = 1 THEN 'Top' ELSE 'Other' END AS rank_category
        FROM union_agg
    )
SELECT
    id,
    total_return_amount,
    cnt,
    rnk,
    rank_category
FROM ranked
ORDER BY rnk
LIMIT 100
