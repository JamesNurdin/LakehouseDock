WITH
    cs_agg AS (
        SELECT
            cs_item_sk,
            cs_call_center_sk,
            cs_ship_mode_sk,
            cs_warehouse_sk,
            cs_sold_time_sk,
            cs_bill_customer_sk,
            SUM(cs_net_paid) AS total_net_paid
        FROM catalog_sales
        GROUP BY cs_item_sk, cs_call_center_sk, cs_ship_mode_sk, cs_warehouse_sk, cs_sold_time_sk, cs_bill_customer_sk
    ),
    store_ret_sample AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    web_ret AS (
        SELECT *
        FROM web_returns
    ),
    full_ret AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_return_quantity AS sr_qty,
            sr.sr_return_amt      AS sr_amt,
            wr.wr_return_quantity AS wr_qty,
            wr.wr_return_amt      AS wr_amt
        FROM store_ret_sample sr
        FULL OUTER JOIN web_ret wr
            ON sr.sr_item_sk = wr.wr_item_sk
    ),
    union_ret AS (
        SELECT sr.sr_item_sk AS item_sk, sr.sr_return_quantity AS qty, sr.sr_return_amt AS amt
        FROM store_ret_sample sr
        UNION DISTINCT
        SELECT wr.wr_item_sk, wr.wr_return_quantity, wr.wr_return_amt
        FROM web_ret wr
    ),
    intersect_items AS (
        SELECT sr.sr_item_sk
        FROM store_ret_sample sr
        INTERSECT
        SELECT wr.wr_item_sk
        FROM web_ret wr
    )
SELECT
    cs_agg.cs_item_sk,
    i.i_item_desc,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    t_sold.t_hour,
    c.c_preferred_cust_flag,
    hd.hd_income_band_sk,
    r.r_reason_desc,
    s.s_store_name,
    ws.ws_ext_tax,
    CASE WHEN cs_agg.total_net_paid > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    word
FROM cs_agg
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t_sold
    ON cs_agg.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer c
    ON cs_agg.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN store_ret_sample sr
    ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN time_dim t_ship
    ON ws.ws_sold_time_sk = t_ship.t_time_sk
LEFT JOIN full_ret fr
    ON fr.sr_item_sk = i.i_item_sk
LEFT JOIN intersect_items ii
    ON ii.sr_item_sk = i.i_item_sk
LEFT JOIN union_ret ur
    ON ur.item_sk = i.i_item_sk
CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
LIMIT 100
