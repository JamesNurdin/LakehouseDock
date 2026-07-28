WITH base AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_date_sk,
        d.d_year,
        i.i_item_sk,
        i.i_brand,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        COALESCE(cr.cr_return_quantity, 0) AS cr_return_quantity,
        COALESCE(cr.cr_return_amount, 0) AS cr_return_amount,
        COALESCE(wr.wr_return_quantity, 0) AS wr_return_quantity,
        COALESCE(wr.wr_return_amt, 0) AS wr_return_amt,
        inv.inv_quantity_on_hand,
        w.w_state,
        cc.cc_county
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                 AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                             AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                             AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk OR wr.wr_reason_sk = r.r_reason_sk
),

daily_agg AS (
    SELECT
        ss_store_sk,
        s_store_name,
        s_state,
        d_year,
        i_brand,
        i_item_sk,
        d_date_sk,
        w_state,
        cc_county,
        SUM(ss_quantity) AS day_quantity,
        SUM(ss_sales_price) AS day_sales,
        SUM(ss_net_paid) AS day_net_paid,
        SUM(cr_return_quantity) AS day_return_qty,
        SUM(cr_return_amount) AS day_return_amt,
        SUM(wr_return_quantity) AS day_web_ret_qty,
        SUM(wr_return_amt) AS day_web_ret_amt,
        AVG(inv_quantity_on_hand) AS day_avg_inventory
    FROM base
    GROUP BY ss_store_sk, s_store_name, s_state, d_year, i_brand, i_item_sk, d_date_sk, w_state, cc_county
)
SELECT
    s_store_name,
    d_year,
    i_brand,
    SUM(day_quantity) AS total_quantity_sold,
    SUM(day_sales) AS total_sales,
    SUM(day_net_paid) AS total_net_paid,
    SUM(day_return_qty) AS total_return_quantity,
    SUM(day_return_amt) AS total_return_amount,
    SUM(day_web_ret_qty) AS total_web_return_quantity,
    SUM(day_web_ret_amt) AS total_web_return_amount,
    AVG(day_avg_inventory) AS avg_inventory_on_hand
FROM daily_agg
WHERE d_year = 2001
  AND s_state = 'CA'
  AND i_brand = 'Brand#23'
  AND w_state = 'WA'
  AND cc_county = 'Jefferson Davis Parish'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = daily_agg.d_date_sk
          AND cr2.cr_item_sk = daily_agg.i_item_sk
          AND cr2.cr_return_quantity > 0
    )
GROUP BY s_store_name, d_year, i_brand
HAVING SUM(day_sales) > 100000
ORDER BY total_sales DESC
LIMIT 100
