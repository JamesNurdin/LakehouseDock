WITH
    returns_agg AS (
        SELECT
            cr.cr_item_sk,
            cr.cr_catalog_page_sk,
            cr.cr_returned_time_sk,
            cr.cr_refunded_addr_sk,
            cr.cr_refunded_hdemo_sk,
            cr.cr_returning_customer_sk,
            SUM(cr.cr_return_quantity)           AS ret_qty,
            SUM(cr.cr_return_amount)            AS ret_amount,
            MIN(cr.cr_order_number)             AS ret_order_num,
            COUNT(DISTINCT cr.cr_order_number)  AS ret_order_cnt
        FROM catalog_returns cr
        GROUP BY cr.cr_item_sk,
                 cr.cr_catalog_page_sk,
                 cr.cr_returned_time_sk,
                 cr.cr_refunded_addr_sk,
                 cr.cr_refunded_hdemo_sk,
                 cr.cr_returning_customer_sk
    ),
    sales_agg AS (
        SELECT
            ws.ws_item_sk,
            ws.ws_sold_time_sk,
            ws.ws_bill_addr_sk,
            ws.ws_bill_hdemo_sk,
            SUM(ws.ws_quantity)           AS total_qty,
            SUM(ws.ws_net_paid)           AS total_net_paid,
            MIN(ws.ws_order_number)       AS ws_order_num,
            COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt
        FROM web_sales ws
        GROUP BY ws.ws_item_sk,
                 ws.ws_sold_time_sk,
                 ws.ws_bill_addr_sk,
                 ws.ws_bill_hdemo_sk
    ),
    item_sales_dim AS (
        SELECT
            i.i_item_sk,
            i.i_item_desc,
            i.i_current_price,
            s.total_qty,
            s.total_net_paid,
            s.ws_order_cnt,
            s.ws_sold_time_sk,
            s.ws_bill_addr_sk,
            s.ws_bill_hdemo_sk
        FROM sales_agg s
        RIGHT OUTER JOIN item i
            ON s.ws_item_sk = i.i_item_sk
    ),
    full_combined AS (
        SELECT
            r.cr_item_sk,
            r.cr_catalog_page_sk,
            r.cr_returned_time_sk,
            r.cr_refunded_addr_sk,
            r.cr_refunded_hdemo_sk,
            r.cr_returning_customer_sk,
            r.ret_qty,
            r.ret_amount,
            r.ret_order_num,
            r.ret_order_cnt,
            i.i_item_sk,
            i.i_item_desc,
            i.i_current_price,
            i.total_qty,
            i.total_net_paid,
            i.ws_order_cnt,
            i.ws_sold_time_sk,
            i.ws_bill_addr_sk,
            i.ws_bill_hdemo_sk
        FROM returns_agg r
        FULL OUTER JOIN item_sales_dim i
            ON r.cr_item_sk = i.i_item_sk
           AND r.cr_returned_time_sk = i.ws_sold_time_sk
    ),
    joined_all AS (
        SELECT
            fc.*,
            cp.cp_department,
            td.t_hour,
            td.t_meal_time,
            ca_ref.ca_state           AS refunded_state,
            ca_bill.ca_state          AS bill_state,
            hd_ref.hd_income_band_sk  AS ref_income_band_sk,
            hd_bill.hd_income_band_sk AS bill_income_band_sk,
            ib_ref.ib_lower_bound    AS ref_income_low,
            ib_ref.ib_upper_bound    AS ref_income_up,
            ib_bill.ib_lower_bound   AS bill_income_low,
            ib_bill.ib_upper_bound   AS bill_income_up
        FROM full_combined fc
        LEFT JOIN catalog_page cp
            ON fc.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN time_dim td
            ON COALESCE(fc.cr_returned_time_sk, fc.ws_sold_time_sk) = td.t_time_sk
        LEFT JOIN customer_address ca_ref
            ON fc.cr_refunded_addr_sk = ca_ref.ca_address_sk
        LEFT JOIN customer_address ca_bill
            ON fc.ws_bill_addr_sk = ca_bill.ca_address_sk
        LEFT JOIN household_demographics hd_ref
            ON fc.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        LEFT JOIN household_demographics hd_bill
            ON fc.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        LEFT JOIN income_band ib_ref
            ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
        LEFT JOIN income_band ib_bill
            ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    ),
    except_orders AS (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        EXCEPT
        SELECT ws.ws_order_number
        FROM web_sales ws
    ),
    common_customers AS (
        SELECT cr.cr_returning_customer_sk
        FROM catalog_returns cr
        INTERSECT
        SELECT ws.ws_bill_customer_sk
        FROM web_sales ws
    )
SELECT
    ja.i_item_desc,
    ja.i_current_price,
    ja.cp_department,
    ja.refunded_state,
    ja.bill_state,
    ja.ref_income_low,
    ja.ref_income_up,
    ja.bill_income_low,
    ja.bill_income_up,
    ja.t_hour,
    ja.t_meal_time,
    ja.ret_qty,
    ja.ret_amount,
    ja.total_qty,
    ja.total_net_paid,
    ja.ret_order_cnt,
    ja.ws_order_cnt,
    CASE
        WHEN ja.ret_amount > 1000 THEN 'HIGH_RETURN'
        ELSE 'LOW_RETURN'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY ja.cp_department ORDER BY ja.ret_amount DESC) AS dept_ret_rank,
    DENSE_RANK() OVER (PARTITION BY ja.refunded_state ORDER BY ja.total_qty DESC) AS state_qty_rank
FROM joined_all ja
WHERE
    ja.t_hour BETWEEN 8 AND 20
    AND ja.ref_income_low >= 50000
    AND ja.i_current_price > 20
    AND ja.cp_department IS NOT NULL
    AND ja.t_meal_time = 'Dinner'
    AND ja.ret_order_num IN (SELECT cr_order_number FROM except_orders)
    AND ja.cr_returning_customer_sk IN (SELECT cr_returning_customer_sk FROM common_customers)
ORDER BY ja.ret_amount DESC
LIMIT 100
