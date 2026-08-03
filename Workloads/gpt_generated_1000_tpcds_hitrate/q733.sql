WITH cs AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_ship_date_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_ship_mode_sk,
        cs_warehouse_sk,
        cs_item_sk,
        cs_bill_hdemo_sk,
        cs_quantity,
        cs_net_paid,
        cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 0
),
agg AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_store_name,
        cc.cc_manager,
        cp.cp_description,
        sm.sm_type,
        w.w_warehouse_name,
        hd.hd_buy_potential,
        ws.ws_net_paid,
        SUM(cs.cs_net_paid)               AS total_net_paid,
        SUM(cs.cs_quantity)               AS total_qty,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count,
        i.i_item_desc                     AS item_description
    FROM cs
    JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk = t.t_time_sk
    RIGHT JOIN store s            ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i                   ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
                                 AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws             ON ws.ws_item_sk = i.i_item_sk
                                 AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN (
        SELECT d2.d_date_sk
        FROM date_dim d2
        WHERE d2.d_year = 2001
    ) d_ship                    ON cs.cs_ship_date_sk = d_ship.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_department = 'Sports'
          AND cp2.cp_catalog_page_sk = cs.cs_catalog_page_sk
    )
      AND t.t_shift = 'first'
    GROUP BY
        d.d_year,
        i.i_category,
        s.s_store_name,
        cc.cc_manager,
        cp.cp_description,
        sm.sm_type,
        w.w_warehouse_name,
        hd.hd_buy_potential,
        ws.ws_net_paid,
        i.i_item_desc
)
SELECT
    a.d_year,
    a.i_category,
    a.total_net_paid,
    CASE WHEN a.total_qty > 100 THEN 'HIGH' ELSE 'LOW' END AS quantity_flag,
    LAG(a.total_net_paid) OVER (PARTITION BY a.i_category ORDER BY a.d_year) AS lag_total_net_paid,
    a.orders_count,
    a.s_store_name,
    a.cc_manager,
    a.cp_description,
    a.sm_type,
    a.w_warehouse_name,
    a.hd_buy_potential,
    a.ws_net_paid,
    w_tok AS word_token
FROM agg a
CROSS JOIN UNNEST(SPLIT(a.item_description, ' ')) AS t(w_tok)
ORDER BY a.total_net_paid DESC
LIMIT 100
