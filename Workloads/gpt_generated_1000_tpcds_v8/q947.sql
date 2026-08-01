WITH cc_dates AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        d.d_date_sk,
        d.d_year
    FROM call_center cc
    FULL OUTER JOIN date_dim d
        ON cc.cc_open_date_sk = d.d_date_sk
),
joined_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        cd.cc_name,
        cd.cc_state,
        sm.sm_type,
        d.d_year,
        inv.inv_quantity_on_hand,
        cr.cr_net_loss
    FROM catalog_sales cs
    JOIN cc_dates cd
        ON cs.cs_call_center_sk = cd.cc_call_center_sk
        AND cs.cs_sold_date_sk = cd.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_item_sk = cs.cs_item_sk
    WHERE d.d_year = 2001
      AND cd.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cs.cs_quantity > 5
      AND inv.inv_quantity_on_hand >= 0
),
agg_per_cc AS (
    SELECT
        cc_name AS grp_key,
        d_year,
        SUM(cs_net_paid_inc_ship) AS total_paid,
        SUM(cs_quantity) AS total_qty,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        SUM(COALESCE(cr_net_loss, 0)) AS total_return_loss
    FROM joined_data
    GROUP BY cc_name, d_year
),
agg_per_sm AS (
    SELECT
        sm_type AS grp_key,
        d_year,
        SUM(cs.cs_net_paid_inc_ship) AS total_paid
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
    GROUP BY sm_type, d_year
),
unioned AS (
    SELECT grp_key, d_year, total_paid FROM agg_per_cc
    UNION
    SELECT grp_key, d_year, total_paid FROM agg_per_sm
),
orders_without_returns AS (
    SELECT cs_order_number FROM catalog_sales
    EXCEPT
    SELECT cr_order_number FROM catalog_returns
),
final AS (
    SELECT
        u.grp_key,
        u.d_year,
        u.total_paid,
        (SELECT COUNT(*) FROM orders_without_returns) AS orders_without_returns_cnt
    FROM unioned u
    ORDER BY u.total_paid DESC
    OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY
)
SELECT * FROM final
