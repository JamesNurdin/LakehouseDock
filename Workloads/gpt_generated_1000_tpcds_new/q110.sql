WITH base AS (
    SELECT
        d.d_date,
        d.d_year,
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_gmt_offset,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_number,
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_call_center_sk,
        i.i_item_sk,
        i.i_category_id,
        i.i_current_price,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ca.ca_address_sk,
        ca.ca_state,
        t.t_time_sk,
        t.t_hour,
        wr.wr_order_number,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wp.wp_web_page_sk,
        wp.wp_url,
        ws.web_site_sk,
        ws.web_name,
        ws.web_tax_percentage,
        s.s_store_sk,
        s.s_store_name
    FROM date_dim d
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE
        d.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
        AND i.i_category_id IN (2, 5, 8)
        AND i.i_current_price > 20
        AND hd.hd_income_band_sk BETWEEN 10 AND 20
        AND cc.cc_gmt_offset BETWEEN -5 AND 0
        AND ws.web_tax_percentage < 5
        AND cr.cr_call_center_sk IN (
            SELECT cc2.cc_call_center_sk FROM call_center cc2 WHERE cc2.cc_employees > 150
        )
),
union_set AS (
    SELECT b.cr_order_number AS order_num,
           b.cr_return_amount,
           b.i_current_price,
           b.d_year
    FROM base b
    WHERE b.cr_return_quantity >= 2

    UNION

    SELECT b.wr_order_number AS order_num,
           b.wr_return_amt AS cr_return_amount,
           b.i_current_price,
           b.d_year
    FROM base b
    WHERE b.wr_return_quantity >= 2
),
intersect_set AS (
    SELECT order_num FROM union_set
    INTERSECT
    SELECT cr.cr_order_number
    FROM base cr
    WHERE cr.cr_net_loss > 0
)
SELECT
    b.d_date,
    b.cc_name,
    b.s_store_name,
    b.i_category_id,
    b.i_current_price,
    b.cr_return_amount,
    b.cr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY b.cc_name ORDER BY b.cr_net_loss DESC) AS loss_rank
FROM base b
JOIN intersect_set iset ON b.cr_order_number = iset.order_num
ORDER BY loss_rank ASC, b.d_date DESC
LIMIT 100
