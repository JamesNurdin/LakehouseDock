WITH intersect_items AS (
        SELECT cr_item_sk FROM catalog_returns
        INTERSECT
        SELECT wr_item_sk FROM web_returns
    ),
    catalog_filtered AS (
        SELECT cr.*
        FROM catalog_returns cr
        WHERE cr.cr_warehouse_sk IN (
                SELECT w_warehouse_sk FROM warehouse WHERE w_city = 'Cincinnati'
            )
          AND cr.cr_item_sk IN (SELECT cr_item_sk FROM intersect_items)
    ),
    web_filtered AS (
        SELECT wr.*
        FROM web_returns wr
        WHERE wr.wr_reason_sk IN (
                SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%Damaged%'
            )
          AND wr.wr_item_sk IN (SELECT cr_item_sk FROM intersect_items)
    ),
    catalog_enriched AS (
        SELECT
            cc.cc_name,
            ws.web_name,
            w.w_warehouse_name,
            i.i_brand,
            cf.cr_return_amount,
            cf.cr_return_tax,
            d_ret.d_year,
            ib.ib_upper_bound
        FROM catalog_filtered cf
        JOIN item i ON cf.cr_item_sk = i.i_item_sk
        JOIN call_center cc ON cf.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cf.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cf.cr_reason_sk = r.r_reason_sk
        JOIN date_dim d_ret ON cf.cr_returned_date_sk = d_ret.d_date_sk
        JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
        JOIN web_site ws ON ws.web_close_date_sk = d_cc.d_date_sk
        JOIN customer c ON cf.cr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cf.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d_ret.d_year = 2002
          AND i.i_current_price BETWEEN 20 AND 100
          AND cc.cc_state = 'CA'
          AND w.w_state = 'CA'
          AND ib.ib_upper_bound >= 60000
    ),
    web_enriched AS (
        SELECT
            cc.cc_name,
            ws.web_name,
            NULL AS w_warehouse_name,
            i.i_brand,
            wr.wr_return_amt AS cr_return_amount,
            wr.wr_return_tax AS cr_return_tax,
            d.d_year,
            ib.ib_upper_bound
        FROM web_filtered wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
        -- join to call_center through the same date dimension used for the web site open date
        JOIN date_dim d_cc ON ws.web_open_date_sk = d_cc.d_date_sk
        JOIN call_center cc ON cc.cc_open_date_sk = d_cc.d_date_sk
        WHERE d.d_year = 2002
          AND i.i_current_price BETWEEN 20 AND 100
          AND ib.ib_upper_bound >= 60000
    )
SELECT
    COALESCE(ca.cc_name, we.cc_name) AS call_center_name,
    COALESCE(ca.web_name, we.web_name) AS web_site_name,
    COALESCE(ca.w_warehouse_name, we.w_warehouse_name) AS warehouse_name,
    COALESCE(ca.i_brand, we.i_brand) AS brand,
    SUM(COALESCE(ca.cr_return_amount, 0) + COALESCE(we.cr_return_amount, 0)) AS total_return_amount,
    COUNT(*) AS total_records,
    AVG(COALESCE(ca.cr_return_tax, 0) + COALESCE(we.cr_return_tax, 0)) AS avg_return_tax,
    MIN(COALESCE(ca.cr_return_amount, we.cr_return_amount)) AS min_return_amount,
    MAX(COALESCE(ca.cr_return_amount, we.cr_return_amount)) AS max_return_amount
FROM catalog_enriched ca
FULL OUTER JOIN web_enriched we
    ON ca.cc_name = we.cc_name
   AND ca.web_name = we.web_name
   AND ca.i_brand = we.i_brand
GROUP BY
    COALESCE(ca.cc_name, we.cc_name),
    COALESCE(ca.web_name, we.web_name),
    COALESCE(ca.w_warehouse_name, we.w_warehouse_name),
    COALESCE(ca.i_brand, we.i_brand)
ORDER BY total_return_amount DESC
LIMIT 100
