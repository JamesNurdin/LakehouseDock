WITH base AS (
    SELECT
        cc.cc_name AS cc_name,
        cp.cp_department AS cp_department,
        i.i_item_id AS i_item_id,
        i.i_current_price AS i_current_price,
        s.s_store_name AS s_store_name,
        s.s_state AS s_state,
        sm.sm_type AS sm_type,
        d.d_date AS d_date,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        cr.cr_return_amount AS cr_return_amount,
        sr.sr_return_amt AS sr_return_amt,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        (cr.cr_return_amount + sr.sr_return_amt + ws.ws_ext_sales_price) AS total_amount
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 100
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
),
first_half AS (
    SELECT DISTINCT
        cc_name,
        cp_department,
        i_item_id,
        i_current_price,
        s_store_name,
        s_state,
        sm_type,
        d_date,
        total_amount
    FROM base
    WHERE d_month_seq <= 6
),
second_half AS (
    SELECT DISTINCT
        cc_name,
        cp_department,
        i_item_id,
        i_current_price,
        s_store_name,
        s_state,
        sm_type,
        d_date,
        total_amount
    FROM base
    WHERE d_month_seq > 6
)
SELECT
    cc_name,
    cp_department,
    i_item_id,
    i_current_price,
    s_store_name,
    s_state,
    sm_type,
    d_date,
    total_amount,
    RANK() OVER (PARTITION BY s_store_name ORDER BY total_amount DESC) AS store_rank
FROM (
    SELECT * FROM first_half
    UNION ALL
    SELECT * FROM second_half
) AS combined
ORDER BY total_amount DESC
LIMIT 100
