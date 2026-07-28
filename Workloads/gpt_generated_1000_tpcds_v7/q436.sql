WITH joined_data AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returned_date_sk,
        i.i_item_id,
        i.i_current_price,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        p.p_promo_id,
        ss.ss_quantity AS store_qty,
        s.s_state,
        w.w_state AS warehouse_state,
        ws.ws_quantity AS web_qty,
        wp.wp_type
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
)
SELECT
    ca_state,
    c_customer_id,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_return_quantity) AS total_return_qty,
    AVG(i_current_price) AS avg_item_price,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(cr_return_amount) DESC) AS rn_state,
    DENSE_RANK() OVER (ORDER BY SUM(cr_return_amount) DESC) AS dr_global
FROM joined_data
WHERE
    cr_return_amount > 50
    AND i_current_price BETWEEN 10 AND 20
    AND s_state = 'CA'
GROUP BY
    ca_state,
    c_customer_id
HAVING SUM(cr_return_amount) > 100
ORDER BY total_return_amount DESC
LIMIT 20
