WITH avg_item_return AS (
    SELECT i_item_sk,
           AVG(sr_return_amt) AS avg_ret_amt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i_item_sk
),
joined AS (
    SELECT
        s.s_store_name,
        d_ret.d_date,
        i.i_category,
        i.i_brand,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        w.w_warehouse_name,
        cc.cc_name AS call_center_name,
        cp.cp_catalog_number,
        avg_item_return.avg_ret_amt
    FROM store_returns sr
    RIGHT OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_date_sk = d_ret.d_date_sk
    LEFT JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc
        ON cc.cc_open_date_sk = d_ret.d_date_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    LEFT JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    LEFT JOIN avg_item_return
        ON i.i_item_sk = avg_item_return.i_item_sk
    GROUP BY
        s.s_store_name,
        d_ret.d_date,
        i.i_category,
        i.i_brand,
        w.w_warehouse_name,
        cc.cc_name,
        cp.cp_catalog_number,
        avg_item_return.avg_ret_amt
)
SELECT
    rn,
    s_store_name,
    d_date,
    i_category,
    i_brand,
    total_return_amount,
    total_return_qty,
    total_inventory_qty,
    w_warehouse_name,
    call_center_name,
    cp_catalog_number,
    avg_ret_amt
FROM (
    SELECT
        ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn,
        s_store_name,
        d_date,
        i_category,
        i_brand,
        total_return_amount,
        total_return_qty,
        total_inventory_qty,
        w_warehouse_name,
        call_center_name,
        cp_catalog_number,
        avg_ret_amt
    FROM joined
) t
ORDER BY rn
LIMIT 100
