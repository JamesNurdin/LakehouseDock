WITH sr_agg AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        i.i_item_sk,
        i.i_product_name,
        s.s_store_sk,
        s.s_store_name,
        r.r_reason_desc,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_tax) AS total_return_tax,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_current_price > 100
    GROUP BY d.d_date_sk, d.d_date, i.i_item_sk, i.i_product_name,
             s.s_store_sk, s.s_store_name, r.r_reason_desc
),
ws_agg AS (
    SELECT
        d.d_date_sk,
        d.d_date,
        i.i_item_sk,
        i.i_product_name,
        sm.sm_ship_mode_id,
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
        SUM(wr.wr_return_amt) AS total_wr_return_amt,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_sales,
        COUNT(DISTINCT wr.wr_order_number) AS cnt_returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND w.w_county = 'San Miguel County'
    GROUP BY d.d_date_sk, d.d_date, i.i_item_sk, i.i_product_name,
             sm.sm_ship_mode_id, w.w_warehouse_sk
),
full_agg AS (
    SELECT
        COALESCE(a.d_date_sk, b.d_date_sk) AS d_date_sk,
        COALESCE(a.d_date, b.d_date) AS d_date,
        COALESCE(a.i_item_sk, b.i_item_sk) AS i_item_sk,
        COALESCE(a.i_product_name, b.i_product_name) AS i_product_name,
        a.total_return_amt,
        b.total_net_paid,
        CASE
            WHEN a.total_return_amt IS NULL THEN 'WebOnly'
            WHEN b.total_net_paid IS NULL THEN 'StoreOnly'
            WHEN a.total_return_amt > b.total_net_paid THEN 'StoreHigher'
            ELSE 'WebHigher'
        END AS higher_source
    FROM sr_agg a
    FULL OUTER JOIN ws_agg b
        ON a.d_date_sk = b.d_date_sk
       AND a.i_item_sk = b.i_item_sk
),
union_data AS (
    SELECT
        d_date,
        i_item_sk,
        i_product_name,
        total_return_amt AS metric,
        cnt_returns AS cnt,
        'StoreReturn' AS src
    FROM sr_agg
    UNION ALL
    SELECT
        d_date,
        i_item_sk,
        i_product_name,
        total_net_paid AS metric,
        cnt_sales AS cnt,
        'WebSale' AS src
    FROM ws_agg
),
joined AS (
    SELECT
        u.d_date,
        u.i_item_sk,
        u.i_product_name,
        u.metric,
        u.cnt,
        u.src,
        fa.higher_source
    FROM union_data u
    LEFT JOIN full_agg fa
        ON u.d_date = fa.d_date
       AND u.i_item_sk = fa.i_item_sk
)
SELECT
    d_date,
    i_item_sk,
    i_product_name,
    src,
    SUM(metric) AS total_metric,
    COUNT(*) AS num_records,
    COALESCE(higher_source, 'NoMatch') AS source_comparison
FROM joined
WHERE metric > 5000
GROUP BY d_date, i_item_sk, i_product_name, src, higher_source
HAVING COUNT(*) >= 2
ORDER BY total_metric DESC, d_date
LIMIT 100
